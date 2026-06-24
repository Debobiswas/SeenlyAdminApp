-- Seenly Admin App backend requirements

-- Ensure profiles table has necessary columns for target review
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS full_name TEXT;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT;

-- Create a separate admins table
CREATE TABLE IF NOT EXISTS public.admins (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin',
  is_admin BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on admins table
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- Allow admins to read the admins table (drop first to prevent already exists error)
DROP POLICY IF EXISTS admins_select_admins_only ON public.admins;
CREATE POLICY admins_select_admins_only
ON public.admins
FOR SELECT
TO authenticated
USING (
  id = auth.uid()
);

-- Create audit logs table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL REFERENCES auth.users(id),
  target_user_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL CHECK (action IN ('approved', 'rejected')),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on audit logs
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can select from audit logs (drop first to prevent already exists error)
DROP POLICY IF EXISTS admin_audit_logs_select_admins_only ON public.admin_audit_logs;
CREATE POLICY admin_audit_logs_select_admins_only
ON public.admin_audit_logs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.admins
    WHERE id = auth.uid()
  )
);

-- View to include target profile info in audit logs
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

-- Function to get pending profiles (admin only)
CREATE OR REPLACE FUNCTION public.get_pending_profiles()
RETURNS SETOF public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.admins
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: admin privileges required';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.profiles
  WHERE status = 'pending'
  ORDER BY created_at DESC;
END;
$$;

-- Function to get admin audit logs (admin only)
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
  IF NOT EXISTS (
    SELECT 1
    FROM public.admins
    WHERE id = auth.uid()
  ) THEN
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

-- Function to approve profile (admin only)
CREATE OR REPLACE FUNCTION public.approve_profile(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.admins
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: admin privileges required';
  END IF;

  UPDATE public.profiles
  SET status = 'active'
  WHERE id = target_user_id;

  INSERT INTO public.admin_audit_logs (
    admin_user_id,
    target_user_id,
    action
  ) VALUES (
    auth.uid(),
    target_user_id,
    'approved'
  );
END;
$$;

-- Function to reject profile (admin only)
CREATE OR REPLACE FUNCTION public.reject_profile(
  target_user_id UUID,
  rejection_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.admins
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: admin privileges required';
  END IF;

  UPDATE public.profiles
  SET status = 'rejected'
  WHERE id = target_user_id;

  INSERT INTO public.admin_audit_logs (
    admin_user_id,
    target_user_id,
    action,
    reason
  ) VALUES (
    auth.uid(),
    target_user_id,
    'rejected',
    rejection_reason
  );
END;
$$;

-- Grants
GRANT SELECT ON public.admins TO authenticated;
GRANT SELECT ON public.admin_audit_logs TO authenticated;
GRANT SELECT ON public.admin_audit_logs_with_targets TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_audit_logs() TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_profile(UUID, TEXT) TO authenticated;
