-- ============================================
-- Sharik - Row Level Security (RLS) Policies
-- ============================================
-- Run this AFTER creating tables
-- Enables security at database level
-- This script is IDEMPOTENT - safe to run multiple times

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE construction_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE handovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE defects ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 1. PROFILES POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 2. PROJECTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view active projects" ON projects;
CREATE POLICY "Anyone can view active projects"
  ON projects FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "Admins can manage projects" ON projects;
CREATE POLICY "Admins can manage projects"
  ON projects FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 3. UNITS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view units" ON units;
CREATE POLICY "Anyone can view units"
  ON units FOR SELECT
  USING (EXISTS (SELECT 1 FROM projects WHERE id = units.project_id AND is_active = true));

DROP POLICY IF EXISTS "Admins can manage units" ON units;
CREATE POLICY "Admins can manage units"
  ON units FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 4. WALLETS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own wallet" ON wallets;
CREATE POLICY "Users can view own wallet"
  ON wallets FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can create wallets" ON wallets;
CREATE POLICY "System can create wallets"
  ON wallets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can update wallets" ON wallets;
CREATE POLICY "Admins can update wallets"
  ON wallets FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 5. TRANSACTIONS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create transactions" ON transactions;
CREATE POLICY "Users can create transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can manage transactions" ON transactions;
CREATE POLICY "Admins can manage transactions"
  ON transactions FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 6. SUBSCRIPTIONS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own subscriptions" ON subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON subscriptions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create subscriptions" ON subscriptions;
CREATE POLICY "Users can create subscriptions"
  ON subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscriptions" ON subscriptions;
CREATE POLICY "Users can update own subscriptions"
  ON subscriptions FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can manage subscriptions" ON subscriptions;
CREATE POLICY "Admins can manage subscriptions"
  ON subscriptions FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 7. INSTALLMENTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own installments" ON installments;
CREATE POLICY "Users can view own installments"
  ON installments FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can manage installments" ON installments;
CREATE POLICY "Admins can manage installments"
  ON installments FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 8. DOCUMENTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own documents" ON documents;
CREATE POLICY "Users can manage own documents"
  ON documents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own documents" ON documents;
CREATE POLICY "Users can update own documents"
  ON documents FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can manage all documents" ON documents;
CREATE POLICY "Admins can manage all documents"
  ON documents FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 9. NOTIFICATIONS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can create notifications" ON notifications;
CREATE POLICY "Admins can create notifications"
  ON notifications FOR INSERT
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 10. CONSTRUCTION_UPDATES POLICIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view public construction updates" ON construction_updates;
CREATE POLICY "Anyone can view public construction updates"
  ON construction_updates FOR SELECT
  USING (is_public = true);

DROP POLICY IF EXISTS "Admins can manage construction updates" ON construction_updates;
CREATE POLICY "Admins can manage construction updates"
  ON construction_updates FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 11. HANDOVERS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own handovers" ON handovers;
CREATE POLICY "Users can view own handovers"
  ON handovers FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own handovers" ON handovers;
CREATE POLICY "Users can update own handovers"
  ON handovers FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can manage handovers" ON handovers;
CREATE POLICY "Admins can manage handovers"
  ON handovers FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 12. DEFECTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own defects" ON defects;
CREATE POLICY "Users can view own defects"
  ON defects FOR SELECT
  USING (EXISTS (SELECT 1 FROM handovers WHERE id = defects.handover_id AND user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can create defects" ON defects;
CREATE POLICY "Users can create defects"
  ON defects FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM handovers WHERE id = handover_id AND user_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can manage defects" ON defects;
CREATE POLICY "Admins can manage defects"
  ON defects FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 13. CONTRACTS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view own contracts" ON contracts;
CREATE POLICY "Users can view own contracts"
  ON contracts FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own contracts" ON contracts;
CREATE POLICY "Users can update own contracts"
  ON contracts FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can manage contracts" ON contracts;
CREATE POLICY "Admins can manage contracts"
  ON contracts FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 14. CONTRACT_TEMPLATES POLICIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view active templates" ON contract_templates;
CREATE POLICY "Anyone can view active templates"
  ON contract_templates FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "Admins can manage templates" ON contract_templates;
CREATE POLICY "Admins can manage templates"
  ON contract_templates FOR ALL
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

-- ============================================
-- 15. ACTIVITY_LOGS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Admins can view activity logs" ON activity_logs;
CREATE POLICY "Admins can view activity logs"
  ON activity_logs FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin'));

DROP POLICY IF EXISTS "System can create activity logs" ON activity_logs;
CREATE POLICY "System can create activity logs"
  ON activity_logs FOR INSERT
  WITH CHECK (true);

-- ============================================
-- RLS POLICIES COMPLETE
-- ============================================
