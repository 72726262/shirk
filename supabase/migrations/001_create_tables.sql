-- ============================================
-- Sharik Real Estate Platform - Database Setup
-- ============================================
-- Run this script in your Supabase SQL Editor
-- This will create all 15 tables with proper relationships

-- ============================================
-- 1. PROFILES TABLE (extends auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  national_id TEXT UNIQUE,
  date_of_birth DATE,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('client', 'admin', 'super_admin')),
  kyc_status TEXT NOT NULL DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'under_review', 'approved', 'rejected')),
  kyc_submitted_at TIMESTAMPTZ,
  kyc_reviewed_at TIMESTAMPTZ,
  kyc_rejection_reason TEXT,
  id_front_url TEXT,
  id_back_url TEXT,
  selfie_url TEXT,
  income_proof_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_kyc_status ON profiles(kyc_status);

-- ============================================
-- 2. PROJECTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,
  status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'in_progress', 'completed', 'on_hold', 'cancelled')),
  location_name TEXT,
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  price_per_sqm DOUBLE PRECISION,
  min_investment DOUBLE PRECISION,
  max_investment DOUBLE PRECISION,
  total_units INTEGER NOT NULL DEFAULT 0,
  sold_units INTEGER NOT NULL DEFAULT 0,
  reserved_units INTEGER NOT NULL DEFAULT 0,
  completion_percentage DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  start_date DATE,
  expected_completion_date DATE,
  actual_completion_date DATE,
  hero_image_url TEXT,
  video_url TEXT,
  render_images JSONB DEFAULT '[]',
  total_partners INTEGER NOT NULL DEFAULT 0,
  featured BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_featured ON projects(featured);
CREATE INDEX IF NOT EXISTS idx_projects_is_active ON projects(is_active);

-- ============================================
-- 3. UNITS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  unit_number TEXT NOT NULL,
  floor INTEGER,
  area_sqm DOUBLE PRECISION NOT NULL,
  price DOUBLE PRECISION NOT NULL,
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'sold', 'blocked')),
  unit_type TEXT NOT NULL CHECK (unit_type IN ('apartment', 'villa', 'shop', 'office', 'land')),
  bedrooms INTEGER,
  bathrooms INTEGER,
  features JSONB DEFAULT '[]',
  floor_plan_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_units_project_id ON units(project_id);
CREATE INDEX IF NOT EXISTS idx_units_status ON units(status);
CREATE INDEX IF NOT EXISTS idx_units_unit_type ON units(unit_type);

-- ============================================
-- 4. WALLETS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  balance DOUBLE PRECISION NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
  reserved_balance DOUBLE PRECISION NOT NULL DEFAULT 0.00 CHECK (reserved_balance >= 0),
  total_deposits DOUBLE PRECISION NOT NULL DEFAULT 0.00,
  total_withdrawals DOUBLE PRECISION NOT NULL DEFAULT 0.00,
  total_payments DOUBLE PRECISION NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);

-- ============================================
-- 5. TRANSACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('deposit', 'withdrawal', 'payment', 'refund', 'commission')),
  amount DOUBLE PRECISION NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  payment_method TEXT CHECK (payment_method IN ('wallet', 'bank_card', 'bank_transfer', 'cash')),
  reference_id TEXT,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- ============================================
-- 6. SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  investment_amount DOUBLE PRECISION NOT NULL,
  ownership_percentage DOUBLE PRECISION,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
  contract_id UUID,
  contract_signed_at TIMESTAMPTZ,
  contract_signature_url TEXT,
  down_payment DOUBLE PRECISION,
  down_payment_paid_at TIMESTAMPTZ,
  installments_count INTEGER NOT NULL DEFAULT 0,
  installments_paid INTEGER NOT NULL DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_project_id ON subscriptions(project_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_unit_id ON subscriptions(unit_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- ============================================
-- 7. INSTALLMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS installments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  installment_number INTEGER NOT NULL,
  amount DOUBLE PRECISION NOT NULL CHECK (amount > 0),
  due_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'waived', 'cancelled')),
  paid_at TIMESTAMPTZ,
  payment_transaction_id UUID REFERENCES transactions(id),
  late_fee_amount DOUBLE PRECISION NOT NULL DEFAULT 0.00,
  late_fee_applied BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_installments_subscription_id ON installments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_installments_user_id ON installments(user_id);
CREATE INDEX IF NOT EXISTS idx_installments_status ON installments(status);
CREATE INDEX IF NOT EXISTS idx_installments_due_date ON installments(due_date);

-- ============================================
-- 8. DOCUMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('contract', 'invoice', 'receipt', 'certificate', 'report', 'kyc', 'other')),
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  file_type TEXT,
  status TEXT NOT NULL DEFAULT 'unsigned' CHECK (status IN ('unsigned', 'signed', 'pending_signature', 'verified', 'expired')),
  signed_at TIMESTAMPTZ,
  signature_url TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  parent_document_id UUID REFERENCES documents(id),
  description TEXT,
  tags JSONB DEFAULT '[]',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_project_id ON documents(project_id);
CREATE INDEX IF NOT EXISTS idx_documents_subscription_id ON documents(subscription_id);
CREATE INDEX IF NOT EXISTS idx_documents_document_type ON documents(document_type);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);

-- ============================================
-- 9. NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  title_ar TEXT,
  body TEXT NOT NULL,
  body_ar TEXT,
  type TEXT NOT NULL CHECK (type IN ('info', 'success', 'warning', 'error', 'update', 'payment', 'kyc', 'document', 'handover')),
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  icon TEXT,
  image_url TEXT,
  action_url TEXT,
  action_label TEXT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- 10. CONSTRUCTION_UPDATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS construction_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  title_ar TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,
  update_type TEXT NOT NULL CHECK (update_type IN ('milestone', 'progress', 'delay', 'issue', 'completion', 'general')),
  completion_percentage DOUBLE PRECISION CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  week_number INTEGER,
  photos JSONB DEFAULT '[]',
  videos JSONB DEFAULT '[]',
  engineering_report_url TEXT,
  financial_report_url TEXT,
  supervision_report_url TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  notify_clients BOOLEAN NOT NULL DEFAULT true,
  update_date DATE NOT NULL,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_construction_updates_project_id ON construction_updates(project_id);
CREATE INDEX IF NOT EXISTS idx_construction_updates_update_date ON construction_updates(update_date DESC);

-- ============================================
-- 11. HANDOVERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS handovers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID UNIQUE NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'appointment_booked', 'inspection_pending', 'defects_submitted', 'defects_fixing', 'ready_for_handover', 'completed', 'cancelled')),
  appointment_date TIMESTAMPTZ,
  appointment_location TEXT,
  appointment_notes TEXT,
  snag_list JSONB DEFAULT '[]',
  defects_count INTEGER NOT NULL DEFAULT 0,
  defects_fixed INTEGER NOT NULL DEFAULT 0,
  handover_signed_at TIMESTAMPTZ,
  signature_url TEXT,
  handover_certificate_url TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_handovers_subscription_id ON handovers(subscription_id);
CREATE INDEX IF NOT EXISTS idx_handovers_user_id ON handovers(user_id);
CREATE INDEX IF NOT EXISTS idx_handovers_status ON handovers(status);

-- ============================================
-- 12. DEFECTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS defects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  handover_id UUID NOT NULL REFERENCES handovers(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('paint', 'flooring', 'plumbing', 'electrical', 'doors', 'windows', 'ceiling', 'walls', 'other')),
  description TEXT NOT NULL,
  location TEXT,
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  photos JSONB DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'acknowledged', 'fixing', 'fixed', 'rejected', 'closed')),
  admin_comment TEXT,
  reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fixed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_defects_handover_id ON defects(handover_id);
CREATE INDEX IF NOT EXISTS idx_defects_status ON defects(status);
CREATE INDEX IF NOT EXISTS idx_defects_severity ON defects(severity);

-- ============================================
-- 13. CONTRACTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  contract_number TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  terms JSONB DEFAULT '{}',
  payment_schedule JSONB DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_signature', 'signed', 'executed', 'terminated', 'expired')),
  client_signed_at TIMESTAMPTZ,
  client_signature_url TEXT,
  client_ip TEXT,
  admin_signed_at TIMESTAMPTZ,
  admin_signature_url TEXT,
  admin_user_id UUID REFERENCES profiles(id),
  pdf_url TEXT,
  effective_date DATE,
  expiry_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contracts_user_id ON contracts(user_id);
CREATE INDEX IF NOT EXISTS idx_contracts_project_id ON contracts(project_id);
CREATE INDEX IF NOT EXISTS idx_contracts_subscription_id ON contracts(subscription_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);

-- ============================================
-- 14. CONTRACT_TEMPLATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS contract_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  template_type TEXT NOT NULL CHECK (template_type IN ('subscription', 'handover', 'payment', 'other')),
  content TEXT NOT NULL,
  content_ar TEXT NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contract_templates_is_active ON contract_templates(is_active);

-- ============================================
-- 15. ACTIVITY_LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON activity_logs(action);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_units_updated_at ON units;
CREATE TRIGGER update_units_updated_at BEFORE UPDATE ON units FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_wallets_updated_at ON wallets;
CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_installments_updated_at ON installments;
CREATE TRIGGER update_installments_updated_at BEFORE UPDATE ON installments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_documents_updated_at ON documents;
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_construction_updates_updated_at ON construction_updates;
CREATE TRIGGER update_construction_updates_updated_at BEFORE UPDATE ON construction_updates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_handovers_updated_at ON handovers;
CREATE TRIGGER update_handovers_updated_at BEFORE UPDATE ON handovers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_defects_updated_at ON defects;
CREATE TRIGGER update_defects_updated_at BEFORE UPDATE ON defects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_contracts_updated_at ON contracts;
CREATE TRIGGER update_contracts_updated_at BEFORE UPDATE ON contracts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_contract_templates_updated_at ON contract_templates;
CREATE TRIGGER update_contract_templates_updated_at BEFORE UPDATE ON contract_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Next steps:
-- 1. Create storage buckets (see storage_setup.sql)
-- 2. Configure RLS policies (see rls_policies.sql)
-- 3. Add test data (see seed_data.sql)
