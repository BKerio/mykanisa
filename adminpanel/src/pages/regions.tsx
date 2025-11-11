import { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { Loader2, Plus, Trash2, Edit3, MapPin } from 'lucide-react';

interface Region {
  id: number;
  name: string;
  presbyteries_count?: number;
  created_at?: string;
}

interface Paginated<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

export default function RegionsPage() {
  const API_URL = import.meta.env.VITE_API_URL;
  const token = useMemo(() => (typeof window !== 'undefined' ? localStorage.getItem('token') : null), []);

  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);
  const [perPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [regions, setRegions] = useState<Region[]>([]);
  const [total, setTotal] = useState(0);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Region | null>(null);
  const [name, setName] = useState('');
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState<number | null>(null);

  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token]);

  const fetchRegions = async () => {
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
      const res = await axios.get<Paginated<Region>>(
        `${API_URL}/admin/regions?${params.toString()}`,
        { headers }
      );
      setRegions(res.data.data);
      setTotal(res.data.total);
    } catch (e: any) {
      setError(e?.response?.data?.message || e?.message || 'Failed to load regions');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const timeout = setTimeout(() => {
      setPage(1);
      fetchRegions();
    }, 300);
    return () => clearTimeout(timeout);
  }, [query]);

  useEffect(() => {
    fetchRegions();
  }, [page, perPage]);

  const resetForm = () => {
    setEditing(null);
    setName('');
  };

  const openCreate = () => {
    resetForm();
    setModalOpen(true);
  };

  const openEdit = (region: Region) => {
    setEditing(region);
    setName(region.name);
    setModalOpen(true);
  };

  const saveRegion = async () => {
    if (!name.trim()) {
      setError('Region name is required');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      if (editing) {
        await axios.put(
          `${API_URL}/admin/regions/${editing.id}`,
          { name: name.trim() },
          { headers }
        );
      } else {
        await axios.post(
          `${API_URL}/admin/regions`,
          { name: name.trim() },
          { headers }
        );
      }
      setModalOpen(false);
      resetForm();
      fetchRegions();
    } catch (e: any) {
      const errorMessage =
        e?.response?.data?.message ||
        e?.response?.data?.error?.name?.[0] ||
        e?.message ||
        'Failed to save region';
      setError(errorMessage);
    } finally {
      setSaving(false);
    }
  };

  const deleteRegion = async (region: Region) => {
    const presbyteryCount = region.presbyteries_count || 0;
    const confirmMessage = presbyteryCount > 0
      ? `Are you sure you want to delete "${region.name}"?\n\nThis will also delete:\n- ${presbyteryCount} presbytery${presbyteryCount !== 1 ? 'ies' : ''} and all associated parishes\n\nThis action cannot be undone!`
      : `Are you sure you want to delete "${region.name}"?\n\nThis action cannot be undone!`;
    
    if (!window.confirm(confirmMessage)) {
      return;
    }

    setDeleting(region.id);
    setError(null);
    try {
      const response = await axios.delete(`${API_URL}/admin/regions/${region.id}`, { headers });
      
      // Show success message with deletion details
      const deletedCounts = response.data?.deleted_counts;
      if (deletedCounts && (deletedCounts.presbyteries > 0 || deletedCounts.parishes > 0)) {
        let message = `Region "${region.name}" deleted successfully.\n\n`;
        if (deletedCounts.presbyteries > 0) {
          message += `- ${deletedCounts.presbyteries} presbyteries deleted\n`;
        }
        if (deletedCounts.parishes > 0) {
          message += `- ${deletedCounts.parishes} parishes deleted\n`;
        }
        alert(message);
      }
      
      fetchRegions();
    } catch (e: any) {
      const errorMessage =
        e?.response?.data?.message ||
        e?.message ||
        'Failed to delete region';
      setError(errorMessage);
      alert(errorMessage); // Show error in alert for delete operations
    } finally {
      setDeleting(null);
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  return (
    <div className="p-6 space-y-6 bg-slate-50 min-h-full">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-800">Regions</h1>
          <p className="text-slate-600 mt-1">Manage church regions</p>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Region
        </button>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}

      {/* Regions Table */}
      <div className="bg-white rounded-xl border border-slate-200/60 shadow-sm">
        <div className="flex items-center justify-between p-4 border-b gap-3">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search regions..."
            className="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent w-64"
          />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Presbyteries
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {loading ? (
                <tr>
                  <td colSpan={3} className="px-4 py-8 text-center text-slate-500">
                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />
                    Loading regions...
                  </td>
                </tr>
              ) : regions.length === 0 ? (
                <tr>
                  <td colSpan={3} className="px-4 py-8 text-center text-slate-500">
                    No regions found.
                  </td>
                </tr>
              ) : (
                regions.map((region) => (
                  <tr key={region.id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 text-sm text-slate-900 font-medium">
                      <div className="flex items-center gap-2">
                        <MapPin className="w-4 h-4 text-blue-600" />
                        {region.name}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-700">
                      {region.presbyteries_count ?? 0} presbytery
                      {region.presbyteries_count !== 1 ? 'ies' : ''}
                    </td>
                    <td className="px-4 py-3 text-sm text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => openEdit(region)}
                          className="inline-flex items-center gap-1 px-3 py-1 border rounded-md hover:bg-slate-50 transition-colors"
                        >
                          <Edit3 className="w-4 h-4" />
                          Edit
                        </button>
                        <button
                          onClick={() => deleteRegion(region)}
                          disabled={deleting === region.id}
                          className="inline-flex items-center gap-1 px-3 py-1 border rounded-md text-red-600 hover:bg-red-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          {deleting === region.id ? (
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

        {/* Pagination */}
        {regions.length > 0 && (
          <div className="flex items-center justify-between p-4 border-t">
            <div className="text-sm text-slate-600">
              Showing {((page - 1) * perPage) + 1} to {Math.min(page * perPage, total)} of {total}{' '}
              regions
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

      {/* Create/Edit Modal */}
      {modalOpen && (
        <div className="fixed inset-0 bg-black/30 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6">
            <h2 className="text-xl font-semibold mb-4">
              {editing ? 'Edit Region' : 'New Region'}
            </h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Region Name <span className="text-red-500">*</span>
                </label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Enter region name"
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      saveRegion();
                    }
                  }}
                />
              </div>
              {editing && editing.presbyteries_count && editing.presbyteries_count > 0 && (
                <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm">
                  <strong>Warning:</strong> This region has {editing.presbyteries_count} presbytery
                  {editing.presbyteries_count !== 1 ? 'ies' : ''}. Deleting this region will permanently delete all associated presbyteries and parishes. This action cannot be undone.
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
                onClick={saveRegion}
                disabled={saving || !name.trim()}
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

