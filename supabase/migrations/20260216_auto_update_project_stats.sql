-- Function to update project stats including total_units
CREATE OR REPLACE FUNCTION update_project_stats(project_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.projects
  SET 
    total_units = (SELECT COUNT(*) FROM public.units WHERE project_id = project_uuid),
    sold_units = (SELECT COUNT(*) FROM public.units WHERE project_id = project_uuid AND status = 'sold'),
    reserved_units = (SELECT COUNT(*) FROM public.units WHERE project_id = project_uuid AND status = 'reserved'),
    total_partners = (SELECT COUNT(DISTINCT user_id) FROM public.subscriptions WHERE project_id = project_uuid AND status = 'active')
  WHERE id = project_uuid;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to call update_project_stats
CREATE OR REPLACE FUNCTION trigger_update_project_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    PERFORM update_project_stats(OLD.project_id);
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE') THEN
    PERFORM update_project_stats(NEW.project_id);
    IF (OLD.project_id IS DISTINCT FROM NEW.project_id) THEN
      PERFORM update_project_stats(OLD.project_id);
    END IF;
    RETURN NEW;
  ELSIF (TG_OP = 'INSERT') THEN
    PERFORM update_project_stats(NEW.project_id);
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger on units table
DROP TRIGGER IF EXISTS on_unit_change ON public.units;
CREATE TRIGGER on_unit_change
AFTER INSERT OR UPDATE OR DELETE ON public.units
FOR EACH ROW EXECUTE FUNCTION trigger_update_project_stats();
