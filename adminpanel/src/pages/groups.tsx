import { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { Loader2, Plus, Trash2, Edit3 } from 'lucide-react';

interface Group {
  id: number;
  name: string;
  description?: string;
  created_at?: string;
}

interface Paginated<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

export default function GroupsPage() {
  const API_URL = import.meta.env.VITE_API_URL;
  const token = useMemo(() => (typeof window !== 'undefined' ? localStorage.getItem('token') : null), []);

  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);
  const [perPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [groups, setGroups] = useState<Group[]>([]);
  const [total, setTotal] = useState(0);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Group | null>(null);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');

  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token]);

  const fetchGroups = async () => {
    if (!token) { setError('Not authenticated'); setLoading(false); return; }
    setLoading(true); setError(null);
    try {
      const params = new URLSearchParams({ q: query, page: String(page), per_page: String(perPage) });
      const res = await axios.get<Paginated<Group>>(`${API_URL}/admin/groups?${params.toString()}`, { headers });
      setGroups(res.data.data); setTotal(res.data.total);
    } catch (e: any) {
      setError(e?.response?.data?.message || e?.message || 'Failed to load groups');
    } finally { setLoading(false); }
  };

  useEffect(() => { const t = setTimeout(() => { setPage(1); fetchGroups(); }, 300); return () => clearTimeout(t); }, [query]);
  useEffect(() => { fetchGroups(); }, [page, perPage]);

  const resetForm = () => { setEditing(null); setName(''); setDescription(''); };
  const openCreate = () => { resetForm(); setModalOpen(true); };
  const openEdit = (g: Group) => { setEditing(g); setName(g.name); setDescription(g.description || ''); setModalOpen(true); };

  const saveGroup = async () => {
    try {
      if (!name.trim()) { setError('Name is required'); return; }
      if (editing) {
        await axios.put(`${API_URL}/admin/groups/${editing.id}`, { name: name.trim(), description: description.trim() || null }, { headers });
      } else {
        await axios.post(`${API_URL}/admin/groups`, { name: name.trim(), description: description.trim() || null }, { headers });
      }
      setModalOpen(false); resetForm(); fetchGroups();
    } catch (e: any) {
      setError(e?.response?.data?.message || e?.message || 'Failed to save group');
    }
  };

  const deleteGroup = async (id: number) => {
    if (!confirm('Delete this group?')) return;
    try {
      await axios.delete(`${API_URL}/admin/groups/${id}`, { headers });
      fetchGroups();
    } catch (e: any) {
      setError(e?.response?.data?.message || e?.message || 'Failed to delete group');
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  return (
    <div className="p-6 space-y-6 bg-slate-50 min-h-full">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-slate-800">All church groups</h1>
        <button onClick={openCreate} className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
          <Plus className="w-4 h-4" /> New Group
        </button>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">{error}</div>}

      <div className="bg-white rounded-xl border border-slate-200/60 shadow-sm">
        <div className="flex items-center justify-between p-4 border-b gap-3">
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search groups..." className="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent w-64" />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Name</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Description</th>
                <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {loading ? (
                <tr>
                  <td colSpan={3} className="px-4 py-8 text-center text-slate-500">
                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" /> Loading groups...
                  </td>
                </tr>
              ) : groups.length === 0 ? (
                <tr>
                  <td colSpan={3} className="px-4 py-8 text-center text-slate-500">No groups found.</td>
                </tr>
              ) : (
                groups.map((g) => (
                  <tr key={g.id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 text-sm text-slate-900 font-medium">{g.name}</td>
                    <td className="px-4 py-3 text-sm text-slate-700">{g.description || '-'}</td>
                    <td className="px-4 py-3 text-sm text-right">
                      <button onClick={() => openEdit(g)} className="inline-flex items-center gap-1 px-3 py-1 border rounded-md hover:bg-slate-50 mr-2">
                        <Edit3 className="w-4 h-4" /> Edit
                      </button>
                      <button onClick={() => deleteGroup(g.id)} className="inline-flex items-center gap-1 px-3 py-1 border rounded-md text-red-600 hover:bg-red-50">
                        <Trash2 className="w-4 h-4" /> Delete
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {groups.length > 0 && (
          <div className="flex items-center justify-between p-4 border-t">
            <div className="text-sm text-slate-600">Showing {((page - 1) * perPage) + 1} to {Math.min(page * perPage, total)} of {total} groups</div>
            <div className="flex items-center gap-2">
              <button onClick={() => setPage(Math.max(1, page - 1))} disabled={page <= 1} className="px-3 py-1 text-sm border rounded-md hover:bg-slate-50 disabled:opacity-50">Previous</button>
              <span className="px-3 py-1 text-sm text-slate-600">Page {page} of {totalPages}</span>
              <button onClick={() => setPage(Math.min(totalPages, page + 1))} disabled={page >= totalPages} className="px-3 py-1 text-sm border rounded-md hover:bg-slate-50 disabled:opacity-50">Next</button>
            </div>
          </div>
        )}
      </div>

      {modalOpen && (
        <div className="fixed inset-0 bg-black/30 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6">
            <h2 className="text-xl font-semibold mb-4">{editing ? 'Edit Group' : 'New Group'}</h2>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium text-slate-700">Name</label>
                <input value={name} onChange={(e) => setName(e.target.value)} className="mt-1 w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
              </div>
              <div>
                <label className="text-sm font-medium text-slate-700">Description</label>
                <textarea value={description} onChange={(e) => setDescription(e.target.value)} className="mt-1 w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent" rows={3} />
              </div>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button onClick={() => { setModalOpen(false); resetForm(); }} className="px-4 py-2 border rounded-lg">Cancel</button>
              <button onClick={saveGroup} className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
