-- ============================================
-- Sharik Real Estate Platform - Complete Database Schema
-- ============================================
-- This script creates all tables, relationships, policies, and functions
-- Run this entire script in your Supabase SQL editor
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- 1. USERS & AUTHENTICATION
-- ============================================

-- User profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  national_id TEXT UNIQUE,
  date_of_birth DATE,
  avatar_url TEXT,
  role TEXT DEFAULT 'client' CHECK (role IN ('client', 'admin', 'super_admin')),
  
  -- KYC Fields
  kyc_status TEXT DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'under_review', 'approved', 'rejected')),
  kyc_submitted_at TIMESTAMPTZ,
  kyc_reviewed_at TIMESTAMPTZ,
  kyc_rejection_reason TEXT,
  id_front_url TEXT,
  id_back_url TEXT,
  selfie_url TEXT,
  income_proof_url TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_national_id ON public.profiles(national_id);
CREATE INDEX IF NOT EXISTS idx_profiles_kyc_status ON public.profiles(kyc_status);

-- ============================================
-- 2. WALLET SYSTEM
-- ============================================

-- Wallets table
CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
  balance DECIMAL(12, 2) DEFAULT 0.00 CHECK (balance >= 0),
  reserved_balance DECIMAL(12, 2) DEFAULT 0.00 CHECK (reserved_balance >= 0),
  total_deposits DECIMAL(12, 2) DEFAULT 0.00,
  total_withdrawals DECIMAL(12, 2) DEFAULT 0.00,
  total_payments DECIMAL(12, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  wallet_id UUID REFERENCES public.wallets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('deposit', 'withdrawal', 'payment', 'refund', 'commission')),
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  payment_method TEXT CHECK (payment_method IN ('wallet', 'bank_card', 'bank_transfer', 'cash')),
  reference_id TEXT, -- External payment reference
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_wallet ON public.transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created ON public.transactions(created_at DESC);

-- ============================================
-- 3. PROJECTS SYSTEM
-- ============================================

-- Projects table
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,
  status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'in_progress', 'completed', 'on_hold', 'cancelled')),
  
  -- Location
  location_name TEXT,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  
  -- Pricing
  price_per_sqm DECIMAL(12, 2),
  min_investment DECIMAL(12, 2),
  max_investment DECIMAL(12, 2),
  total_units INTEGER DEFAULT 0,
  sold_units INTEGER DEFAULT 0,
  reserved_units INTEGER DEFAULT 0,
  
  -- Progress
  completion_percentage DECIMAL(5, 2) DEFAULT 0.00 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  start_date DATE,
  expected_completion_date DATE,
  actual_completion_date DATE,
  
  -- Media
  hero_image_url TEXT,
  video_url TEXT,
  render_images JSONB DEFAULT '[]',
  
  -- Partners
  total_partners INTEGER DEFAULT 0,
  
  -- Metadata
  featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_featured ON public.projects(featured);
CREATE INDEX IF NOT EXISTS idx_projects_active ON public.projects(is_active);

-- ============================================
-- 4. UNITS SYSTEM
-- ============================================

-- Units table
CREATE TABLE IF NOT EXISTS public.units (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  unit_number TEXT NOT NULL,
  floor INTEGER,
  area_sqm DECIMAL(10, 2) NOT NULL,
  price DECIMAL(12, 2) NOT NULL,
  status TEXT DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'sold', 'blocked')),
  unit_type TEXT CHECK (unit_type IN ('apartment', 'villa', 'shop', 'office', 'land')),
  bedrooms INTEGER,
  bathrooms INTEGER,
  features JSONB DEFAULT '[]',
  floor_plan_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(project_id, unit_number)
);

CREATE INDEX IF NOT EXISTS idx_units_project ON public.units(project_id);
CREATE INDEX IF NOT EXISTS idx_units_status ON public.units(status);

-- ============================================
-- 5. SUBSCRIPTIONS (CLIENT JOINS PROJECT)
-- ============================================

-- Subscriptions table
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  
  -- Investment Details
  investment_amount DECIMAL(12, 2) NOT NULL,
  ownership_percentage DECIMAL(5, 2),
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
  
  -- Contract
  contract_id UUID, -- Will reference contracts table
  contract_signed_at TIMESTAMPTZ,
  contract_signature_url TEXT,
  
  -- Payment
  down_payment DECIMAL(12, 2),
  down_payment_paid_at TIMESTAMPTZ,
  installments_count INTEGER DEFAULT 0,
  installments_paid INTEGER DEFAULT 0,
  
  -- Timestamps
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, project_id, unit_id)
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_project ON public.subscriptions(project_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

-- ============================================
-- 6. DOCUMENTS SYSTEM
-- ============================================

-- Documents table
CREATE TABLE IF NOT EXISTS public.documents (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  
  -- Document Details
  document_type TEXT NOT NULL CHECK (document_type IN ('contract', 'invoice', 'receipt', 'certificate', 'report', 'kyc', 'other')),
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER, -- in bytes
  file_type TEXT, -- pdf, jpg, png, etc.
  
  -- Status
  status TEXT DEFAULT 'unsigned' CHECK (status IN ('unsigned', 'signed', 'pending_signature', 'verified', 'expired')),
  signed_at TIMESTAMPTZ,
  signature_url TEXT,
  
  -- Version Control
  version INTEGER DEFAULT 1,
  parent_document_id UUID REFERENCES public.documents(id),
  
  -- Metadata
  description TEXT,
  tags JSONB DEFAULT '[]',
  metadata JSONB DEFAULT '{}',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_user ON public.documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_project ON public.documents(project_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON public.documents(document_type);
CREATE INDEX IF NOT EXISTS idx_documents_status ON public.documents(status);

-- ============================================
-- 7. CONSTRUCTION UPDATES
-- ============================================

-- Construction updates table
CREATE TABLE IF NOT EXISTS public.construction_updates (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  
  -- Update Details
  title TEXT NOT NULL,
  title_ar TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,
  update_type TEXT CHECK (update_type IN ('milestone', 'progress', 'delay', 'issue', 'completion', 'general')),
  
  -- Progress
  completion_percentage DECIMAL(5, 2) CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  week_number INTEGER,
  
  -- Media
  photos JSONB DEFAULT '[]', -- Array of photo URLs
  videos JSONB DEFAULT '[]', -- Array of video URLs
  
  -- Reports
  engineering_report_url TEXT,
  financial_report_url TEXT,
  supervision_report_url TEXT,
  
  -- Visibility
  is_public BOOLEAN DEFAULT true,
  notify_clients BOOLEAN DEFAULT true,
  
  -- Timestamps
  update_date DATE DEFAULT CURRENT_DATE,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_construction_updates_project ON public.construction_updates(project_id);
CREATE INDEX IF NOT EXISTS idx_construction_updates_date ON public.construction_updates(update_date DESC);

-- ============================================
-- 8. NOTIFICATIONS SYSTEM
-- ============================================

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Notification Content
  title TEXT NOT NULL,
  title_ar TEXT,
  body TEXT NOT NULL,
  body_ar TEXT,
  type TEXT CHECK (type IN ('info', 'success', 'warning', 'error', 'update', 'payment', 'kyc', 'document', 'handover')),
  
  -- Related Entities
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL,
  
  -- Media
  icon TEXT,
  image_url TEXT,
  
  -- Action
  action_url TEXT,
  action_label TEXT,
  
  -- Status
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  
  -- Priority
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- ============================================
-- 9. HANDOVER SYSTEM
-- ============================================

-- Handover table
CREATE TABLE IF NOT EXISTS public.handovers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE CASCADE NOT NULL UNIQUE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
  
  -- Status
  status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'appointment_booked', 'inspection_pending', 'defects_submitted', 'defects_fixing', 'ready_for_handover', 'completed', 'cancelled')),
  
  -- Appointment
  appointment_date TIMESTAMPTZ,
  appointment_location TEXT,
  appointment_notes TEXT,
  
  -- SNAG List (Defects)
  snag_list JSONB DEFAULT '[]', -- Array of defect objects
  defects_count INTEGER DEFAULT 0,
  defects_fixed INTEGER DEFAULT 0,
  
  -- Handover Signature
  handover_signed_at TIMESTAMPTZ,
  signature_url TEXT,
  handover_certificate_url TEXT,
  
  -- Timestamps
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_handovers_subscription ON public.handovers(subscription_id);
CREATE INDEX IF NOT EXISTS idx_handovers_user ON public.handovers(user_id);
CREATE INDEX IF NOT EXISTS idx_handovers_status ON public.handovers(status);

-- Defects table (for SNAG list items)
CREATE TABLE IF NOT EXISTS public.defects (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  handover_id UUID REFERENCES public.handovers(id) ON DELETE CASCADE NOT NULL,
  
  -- Defect Details
  category TEXT CHECK (category IN ('paint', 'flooring', 'plumbing', 'electrical', 'doors', 'windows', 'ceiling', 'walls', 'other')),
  description TEXT NOT NULL,
  location TEXT, -- e.g., "Living Room", "Bathroom 1"
  severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  
  -- Photos
  photos JSONB DEFAULT '[]',
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'acknowledged', 'fixing', 'fixed', 'rejected', 'closed')),
  admin_comment TEXT,
  
  -- Timestamps
  reported_at TIMESTAMPTZ DEFAULT NOW(),
  fixed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_defects_handover ON public.defects(handover_id);
CREATE INDEX IF NOT EXISTS idx_defects_status ON public.defects(status);

-- ============================================
-- 10. CONTRACTS SYSTEM
-- ============================================

-- Contract templates
CREATE TABLE IF NOT EXISTS public.contract_templates (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  template_type TEXT CHECK (template_type IN ('subscription', 'handover', 'payment', 'other')),
  content TEXT NOT NULL, -- HTML or Markdown content
  content_ar TEXT NOT NULL,
  version TEXT DEFAULT '1.0',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Generated contracts
CREATE TABLE IF NOT EXISTS public.contracts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  template_id UUID REFERENCES public.contract_templates(id),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  
  -- Contract Content
  contract_number TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL, -- Filled template
  
  -- Terms
  terms JSONB DEFAULT '{}',
  payment_schedule JSONB DEFAULT '[]',
  
  -- Signatures
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_signature', 'signed', 'executed', 'terminated', 'expired')),
  
  -- Client Signature
  client_signed_at TIMESTAMPTZ,
  client_signature_url TEXT,
  client_ip TEXT,
  
  -- Admin Signature
  admin_signed_at TIMESTAMPTZ,
  admin_signature_url TEXT,
  admin_user_id UUID REFERENCES public.profiles(id),
  
  -- Document
  pdf_url TEXT,
  
  -- Timestamps
  effective_date DATE,
  expiry_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contracts_user ON public.contracts(user_id);
CREATE INDEX IF NOT EXISTS idx_contracts_subscription ON public.contracts(subscription_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON public.contracts(status);

-- Add foreign key back to subscriptions
ALTER TABLE public.subscriptions ADD CONSTRAINT fk_subscription_contract FOREIGN KEY (contract_id) REFERENCES public.contracts(id);

-- ============================================
-- 11. PAYMENT SCHEDULES & INSTALLMENTS
-- ============================================

-- Installments table
CREATE TABLE IF NOT EXISTS public.installments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Installment Details
  installment_number INTEGER NOT NULL,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  due_date DATE NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'waived', 'cancelled')),
  paid_at TIMESTAMPTZ,
  payment_transaction_id UUID REFERENCES public.transactions(id),
  
  -- Late Fees
  late_fee_amount DECIMAL(12, 2) DEFAULT 0.00,
  late_fee_applied BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_installments_subscription ON public.installments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_installments_user ON public.installments(user_id);
CREATE INDEX IF NOT EXISTS idx_installments_status ON public.installments(status);
CREATE INDEX IF NOT EXISTS idx_installments_due_date ON public.installments(due_date);

-- ============================================
-- 12. ADMIN ACTIVITY LOGS
-- ============================================

-- Activity logs
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT, -- 'project', 'user', 'payment', etc.
  entity_id UUID,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON public.activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON public.activity_logs(created_at DESC);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON public.wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_units_updated_at BEFORE UPDATE ON public.units FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_construction_updates_updated_at BEFORE UPDATE ON public.construction_updates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_handovers_updated_at BEFORE UPDATE ON public.handovers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_defects_updated_at BEFORE UPDATE ON public.defects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contracts_updated_at BEFORE UPDATE ON public.contracts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_installments_updated_at BEFORE UPDATE ON public.installments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create wallet when user profile is created
CREATE OR REPLACE FUNCTION create_wallet_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.wallets (user_id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_wallet_on_profile_creation
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION create_wallet_for_new_user();

-- Function to create profile when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.construction_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.handovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.defects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contract_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "Admins can update all profiles" ON public.profiles FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Wallets policies
CREATE POLICY "Users can view own wallet" ON public.wallets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can view all wallets" ON public.wallets FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Transactions policies
CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can view all transactions" ON public.transactions FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Projects policies (public read, admin write)
CREATE POLICY "Anyone can view active projects" ON public.projects FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage projects" ON public.projects FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Units policies
CREATE POLICY "Anyone can view available units" ON public.units FOR SELECT USING (true);
CREATE POLICY "Admins can manage units" ON public.units FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Subscriptions policies
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create subscriptions" ON public.subscriptions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can view all subscriptions" ON public.subscriptions FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Documents policies
CREATE POLICY "Users can view own documents" ON public.documents FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can manage all documents" ON public.documents FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Construction updates policies
CREATE POLICY "Anyone can view public updates" ON public.construction_updates FOR SELECT USING (is_public = true);
CREATE POLICY "Admins can manage updates" ON public.construction_updates FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (user_id = auth.uid());

-- Handovers policies
CREATE POLICY "Users can view own handovers" ON public.handovers FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own handovers" ON public.handovers FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Admins can manage all handovers" ON public.handovers FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Defects policies
CREATE POLICY "Users can view own defects" ON public.defects FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.handovers WHERE id = handover_id AND user_id = auth.uid())
);
CREATE POLICY "Users can create defects" ON public.defects FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.handovers WHERE id = handover_id AND user_id = auth.uid())
);
CREATE POLICY "Admins can manage defects" ON public.defects FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Contracts policies
CREATE POLICY "Users can view own contracts" ON public.contracts FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can manage contracts" ON public.contracts FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Contract templates policies (admins only)
CREATE POLICY "Admins can manage templates" ON public.contract_templates FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Installments policies
CREATE POLICY "Users can view own installments" ON public.installments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can manage installments" ON public.installments FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Activity logs (admins only)
CREATE POLICY "Admins can view activity logs" ON public.activity_logs FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to get wallet balance
CREATE OR REPLACE FUNCTION get_wallet_balance(wallet_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  current_balance DECIMAL;
BEGIN
  SELECT balance INTO current_balance
  FROM public.wallets
  WHERE user_id = wallet_user_id;
  
  RETURN COALESCE(current_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update project stats
CREATE OR REPLACE FUNCTION update_project_stats(project_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.projects
  SET 
    sold_units = (SELECT COUNT(*) FROM public.units WHERE project_id = project_uuid AND status = 'sold'),
    reserved_units = (SELECT COUNT(*) FROM public.units WHERE project_id = project_uuid AND status = 'reserved'),
    total_partners = (SELECT COUNT(DISTINCT user_id) FROM public.subscriptions WHERE project_id = project_uuid AND status = 'active')
  WHERE id = project_uuid;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Create default contract template
INSERT INTO public.contract_templates (name, name_ar, template_type, content, content_ar) VALUES
('Standard Subscription Contract', 'عقد اشتراك قياسي', 'subscription', 
 '<h1>Subscription Contract</h1><p>Terms and conditions...</p>',
 '<h1>عقد الاشتراك</h1><p>الشروط والأحكام...</p>')
ON CONFLICT DO NOTHING;

-- ============================================
-- STORAGE BUCKETS (Run in Supabase Dashboard > Storage)
-- ============================================

-- You need to create these buckets manually in Supabase Dashboard:
-- 1. 'kyc-documents' - for KYC uploads
-- 2. 'project-media' - for project images/videos
-- 3. 'construction-updates' - for construction photos/videos
-- 4. 'documents' - for contracts, PDFs
-- 5. 'signatures' - for e-signatures
-- 6. 'handover-photos' - for SNAG list photos
-- 7. 'avatars' - for user profile photos

-- Then set their RLS policies in the Supabase Dashboard

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

-- If you see this message, the schema was created successfully!
DO $$
BEGIN
  RAISE NOTICE 'Sharik العقاري Database Schema Created Successfully! ✅';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Create storage buckets in Supabase Dashboard';
  RAISE NOTICE '2. Setup storage policies';
  RAISE NOTICE '3. Configure Email templates for Auth';
END $$;
