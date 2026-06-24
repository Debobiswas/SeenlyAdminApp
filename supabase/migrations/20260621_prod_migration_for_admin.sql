-- ==========================================
-- Seenly Admin App - Production DB Migration
-- ==========================================

-- 1. Helper Function to Simplify Admin RLS Policies
-- This function checks if the current authenticated user is an admin.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admins WHERE id = auth.uid()
  );
END;
$$;

-- 2. Update Profiles Table
-- The admin app code explicitly relies on `full_name`, while the prod DB currently only has `name`.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
-- Migrate existing 'name' values to 'full_name' for seamless backwards compatibility
UPDATE public.profiles SET full_name = name WHERE full_name IS NULL AND name IS NOT NULL;


-- 3. Create Admins Table
CREATE TABLE IF NOT EXISTS public.admins (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin',
  is_admin BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS admins_select_admins_only ON public.admins;
CREATE POLICY admins_select_admins_only ON public.admins FOR SELECT TO authenticated USING (id = auth.uid());


-- 4. Create Admin Audit Logs Table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL REFERENCES auth.users(id),
  target_user_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL CHECK (action IN ('approved', 'rejected')),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS admin_audit_logs_select_admins_only ON public.admin_audit_logs;
CREATE POLICY admin_audit_logs_select_admins_only ON public.admin_audit_logs FOR SELECT TO authenticated USING (public.is_admin());


-- 5. Create Audit Logs View (with joined Profile Data)
CREATE OR REPLACE VIEW public.admin_audit_logs_with_targets
WITH (security_invoker = true)
AS
SELECT
  logs.id,
  logs.admin_user_id,
  logs.target_user_id,
  logs.action,
  logs.reason,
  logs.created_at,
  target.email AS target_email,
  target.full_name AS target_name
FROM public.admin_audit_logs logs
LEFT JOIN public.profiles target
  ON target.id = logs.target_user_id;

GRANT SELECT ON public.admin_audit_logs_with_targets TO authenticated;

CREATE OR REPLACE FUNCTION public.get_admin_audit_logs()
RETURNS TABLE (
  id UUID,
  admin_user_id UUID,
  target_user_id UUID,
  action TEXT,
  reason TEXT,
  created_at TIMESTAMPTZ,
  target_email TEXT,
  target_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required';
  END IF;

  RETURN QUERY
  SELECT
    logs.id,
    logs.admin_user_id,
    logs.target_user_id,
    logs.action,
    logs.reason,
    logs.created_at,
    target.email AS target_email,
    target.full_name AS target_name
  FROM public.admin_audit_logs logs
  LEFT JOIN public.profiles target
    ON target.id = logs.target_user_id
  ORDER BY logs.created_at DESC;
END;
$$;


-- 6. Add Admin Global Access RLS Policies to Existing Tables
-- Allows admins to perform all CRUD operations across the dashboard's tables.
DO $$ 
DECLARE 
  target_table text;
  tables text[] := ARRAY['profiles', 'venues', 'campaigns', 'reservations', 'user_reports', 'menu_items', 'waitlist', 'feedback', 'feature_flags'];
BEGIN
  FOREACH target_table IN ARRAY tables LOOP
    -- Only try to apply policies to tables that actually exist in the schema
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = target_table) THEN
      EXECUTE format('DROP POLICY IF EXISTS "Admins have full access" ON public.%I', target_table);
      EXECUTE format('CREATE POLICY "Admins have full access" ON public.%I FOR ALL TO authenticated USING (public.is_admin())', target_table);
    END IF;
  END LOOP;
END $$;


-- 7. Admin specific moderation functions
-- Function to get pending profiles
CREATE OR REPLACE FUNCTION public.get_pending_profiles()
RETURNS SETOF public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required';
  END IF;

  RETURN QUERY SELECT * FROM public.profiles WHERE status = 'pending' ORDER BY created_at DESC;
END;
$$;

-- Function to approve profile
CREATE OR REPLACE FUNCTION public.approve_profile(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required';
  END IF;

  UPDATE public.profiles SET status = 'active' WHERE id = target_user_id;

  INSERT INTO public.admin_audit_logs (admin_user_id, target_user_id, action) 
  VALUES (auth.uid(), target_user_id, 'approved');
END;
$$;

-- Function to reject profile
CREATE OR REPLACE FUNCTION public.reject_profile(target_user_id UUID, rejection_reason TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required';
  END IF;

  UPDATE public.profiles SET status = 'rejected' WHERE id = target_user_id;

  INSERT INTO public.admin_audit_logs (admin_user_id, target_user_id, action, reason) 
  VALUES (auth.uid(), target_user_id, 'rejected', rejection_reason);
END;
$$;

-- 8. Apply Grants
GRANT SELECT ON public.admins TO authenticated;
GRANT SELECT ON public.admin_audit_logs TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_profile(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_audit_logs() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- END OF MIGRATION
