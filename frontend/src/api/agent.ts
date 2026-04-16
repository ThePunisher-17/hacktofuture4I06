import axios from 'axios';

const API_BASE = import.meta.env.VITE_AGENT_URL || 'http://localhost:8001';

export interface ActionItemData {
  tool: string;
  action: string;
  details: Record<string, unknown>;
  status: string;
  message: string;
}

export interface ActionResult {
  original_text: string;
  actions_taken: ActionItemData[];
  success: boolean;
  message: string;
}

const client = axios.create({
  baseURL: API_BASE,
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' },
});

export async function sendAction(text: string, orgId: string = 'org-demo-123'): Promise<ActionResult> {
  const { data } = await client.post<ActionResult>('/pipeline/action', {
    text,
    organization_id: orgId,
  });
  return data;
}

export async function checkHealth(): Promise<boolean> {
  try {
    const { data } = await client.get('/health');
    return data?.status === 'ok';
  } catch {
    return false;
  }
}
