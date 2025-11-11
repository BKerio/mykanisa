import { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { Loader2, Plus, Trash2, Edit3, Building2, MapPin } from 'lucide-react';

interface Region {
  id: number;
  name: string;
}

interface Presbytery {
  id: number;
  name: string;
  region_id: number;
  region?: Region;
  parishes_count?: number;
  created_at?: string;
}

interface Paginated<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

export default function PresbyteriesPage() {
  const API_URL = import.meta.env.VITE_API_URL;
  const token = useMemo(() => (typeof window !== 'undefined' ? localStorage.getItem('token') : null), []);

  const [query, setQuery] = useState('');
  const [selectedRegionId, setSelectedRegionId] = useState<string>('');
  const [page, setPage] = useState(1);
  const [perPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [presbyteries, setPresbyteries] = useState<Presbytery[]>([]);
  const [regions, setRegions] = useState<Region[]>([]);
  const [total, setTotal] = useState(0);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Presbytery | null>(null);
  const [name, setName] = useState('');
  const [regionId, setRegionId] = useState<number | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState<number | null>(null);

  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token]);

  const fetchRegions = async () => {
    try {
      const res = await axios.get(`${API_URL}/admin/regions?per_page=1000`, { headers });
      setRegions(res.data.data || []);
    } catch (e: any) {
      console.error('Failed to load regions:', e);
    }
  };

  const fetchPresbyteries = async () => {
    if (!token) {
      setError('Not authenticated');
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        q: query,
        page: String(page),
        per_page: String(perPage),
      });
      if (selectedRegionId) {
        params.append('region_id', selectedRegionId);
      }
      const res = await axios.get<Paginated<Presbytery>>(
        `${API_URL}/admin/presbyteries?${params.toString()}`,
        { headers }
      );
      setPresbyteries(res.data.data);
      setTotal(res.data.total);
    } catch (e: any) {
      setError(e?.response?.data?.message || e?.message || 'Failed to load presbyteries');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRegions();
  }, []);

  useEffect(() => {
    const timeout = setTimeout(() => {
      setPage(1);
      fetchPresbyteries();
    }, 300);
    return () => clearTimeout(timeout);
  }, [query, selectedRegionId]);

  useEffect(() => {
    fetchPresbyteries();
  }, [page, perPage]);

  const resetForm = () => {
    setEditing(null);
    setName('');
    setRegionId(null);
  };

  const openCreate = () => {
    resetForm();
    setModalOpen(true);
  };

  const openEdit = (presbytery: Presbytery) => {
    setEditing(presbytery);
    setName(presbytery.name);
    setRegionId(presbytery.region_id);
    setModalOpen(true);
  };

  const savePresbytery = async () => {
    if (!name.trim()) {
      setError('Presbytery name is required');
      return;
    }
    if (!regionId) {
      setError('Region is required');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      if (editing) {
        await axios.put(
          `${API_URL}/admin/presbyteries/${editing.id}`,
          { name: name.trim(), region_id: regionId },
          { headers }
        );
      } else {
        await axios.post(
          `${API_URL}/admin/presbyteries`,
          { name: name.trim(), region_id: regionId },
          { headers }
        );
      }
      setModalOpen(false);
      resetForm();
      fetchPresbyteries();
    } catch (e: any) {
      const errorMessage =
        e?.response?.data?.message ||
        e?.response?.data?.error?.name?.[0] ||
        e?.message ||
        'Failed to save presbytery';
      setError(errorMessage);
    } finally {
      setSaving(false);
    }
  };

  const deletePresbytery = async (presbytery: Presbytery) => {
    const parishCount = presbytery.parishes_count || 0;
    const confirmMessage = parishCount > 0
      ? `Are you sure you want to delete "${presbytery.name}"?\n\nThis will also delete:\n- ${parishCount} parish${parishCount !== 1 ? 'ies' : ''}\n\nThis action cannot be undone!`
      : `Are you sure you want to delete "${presbytery.name}"?\n\nThis action cannot be undone!`;
    
    if (!window.confirm(confirmMessage)) {
      return;
    }

    setDeleting(presbytery.id);
    setError(null);
    try {
      const response = await axios.delete(`${API_URL}/admin/presbyteries/${presbytery.id}`, { headers });
      
      const deletedCounts = response.data?.deleted_counts;
      if (deletedCounts && deletedCounts.parishes > 0) {
        alert(`Presbytery "${presbytery.name}" deleted successfully.\n\n- ${deletedCounts.parishes} parishes deleted`);
      }
      
      fetchPresbyteries();
    } catch (e: any) {
      const errorMessage =
        e?.response?.data?.message ||
        e?.message ||
        'Failed to delete presbytery';
      setError(errorMessage);
      alert(errorMessage);
    } finally {
      setDeleting(null);
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  return (
    <div className="p-6 space-y-6 bg-slate-50 min-h-full">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-800">Presbyteries</h1>
          <p className="text-slate-600 mt-1">Manage church presbyteries</p>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Presbytery
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}

      <div className="bg-white rounded-xl border border-slate-200/60 shadow-sm">
        <div className="flex items-center justify-between p-4 border-b gap-3 flex-wrap">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search presbyteries..."
            className="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent w-64"
          />
          <select
            value={selectedRegionId}
            onChange={(e) => setSelectedRegionId(e.target.value)}
            className="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Regions</option>
            {regions.map((region) => (
              <option key={region.id} value={region.id}>
                {region.name}
              </option>
            ))}
          </select>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Region
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Parishes
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {loading ? (
                <tr>
                  <td colSpan={4} className="px-4 py-8 text-center text-slate-500">
                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />
                    Loading presbyteries...
                  </td>
                </tr>
              ) : presbyteries.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-8 text-center text-slate-500">
                    No presbyteries found.
                  </td>
                </tr>
              ) : (
                presbyteries.map((presbytery) => (
                  <tr key={presbytery.id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 text-sm text-slate-900 font-medium">
                      <div className="flex items-center gap-2">
                        <Building2 className="w-4 h-4 text-blue-600" />
                        {presbytery.name}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-700">
                      {presbytery.region?.name || 'N/A'}
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-700">
                      {presbytery.parishes_count ?? 0} parish
                      {presbytery.parishes_count !== 1 ? 'ies' : ''}
                    </td>
                    <td className="px-4 py-3 text-sm text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => openEdit(presbytery)}
                          className="inline-flex items-center gap-1 px-3 py-1 border rounded-md hover:bg-slate-50 transition-colors"
                        >
                          <Edit3 className="w-4 h-4" />
                          Edit
                        </button>
                        <button
                          onClick={() => deletePresbytery(presbytery)}
                          disabled={deleting === presbytery.id}
                          className="inline-flex items-center gap-1 px-3 py-1 border rounded-md text-red-600 hover:bg-red-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          {deleting === presbytery.id ? (
                            <Loader2 className="w-4 h-4 animate-spin" />
                          ) : (
                            <Trash2 className="w-4 h-4" />
                          )}
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {presbyteries.length > 0 && (
          <div className="flex items-center justify-between p-4 border-t">
            <div className="text-sm text-slate-600">
              Showing {((page - 1) * perPage) + 1} to {Math.min(page * perPage, total)} of {total}{' '}
              presbyteries
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page <= 1}
                className="px-3 py-1 text-sm border rounded-md hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Previous
              </button>
              <span className="px-3 py-1 text-sm text-slate-600">
                Page {page} of {totalPages}
              </span>
              <button
                onClick={() => setPage(Math.min(totalPages, page + 1))}
                disabled={page >= totalPages}
                className="px-3 py-1 text-sm border rounded-md hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {modalOpen && (
        <div className="fixed inset-0 bg-black/30 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6">
            <h2 className="text-xl font-semibold mb-4">
              {editing ? 'Edit Presbytery' : 'New Presbytery'}
            </h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Region <span className="text-red-500">*</span>
                </label>
                <select
                  value={regionId || ''}
                  onChange={(e) => setRegionId(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  disabled={!!editing}
                >
                  <option value="">Select a region</option>
                  {regions.map((region) => (
                    <option key={region.id} value={region.id}>
                      {region.name}
                    </option>
                  ))}
                </select>
                {editing && (
                  <p className="text-xs text-slate-500 mt-1">Region cannot be changed after creation</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Presbytery Name <span className="text-red-500">*</span>
                </label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Enter presbytery name"
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      savePresbytery();
                    }
                  }}
                />
              </div>
              {editing && editing.parishes_count && editing.parishes_count > 0 && (
                <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm">
                  <strong>Warning:</strong> This presbytery has {editing.parishes_count} parish
                  {editing.parishes_count !== 1 ? 'ies' : ''}. Deleting this presbytery will permanently delete all associated parishes.
                </div>
              )}
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button
                onClick={() => {
                  setModalOpen(false);
                  resetForm();
                  setError(null);
                }}
                className="px-4 py-2 border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={savePresbytery}
                disabled={saving || !name.trim() || !regionId}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
              >
                {saving && <Loader2 className="w-4 h-4 animate-spin" />}
                {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

