-- Harden admin audit-log access behind an explicit admin-checked RPC.

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

GRANT SELECT ON public.admin_audit_logs_with_targets TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_audit_logs() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
