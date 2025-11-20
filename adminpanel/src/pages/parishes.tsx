import { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { 
  Loader2, 
  Plus, 
  Trash2, 
  Edit3, 
  Church, 
  Building2, 
  MapPin, 
  Search, 
  AlertTriangle, 
  X, 
  ChevronLeft, 
  ChevronRight,

} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import DashboardLoader from '@/lib/loader'; 
import Swal from 'sweetalert2';

// --- Types ---
interface Region {
  id: number;
  name: string;
}

interface Presbytery {
  id: number;
  name: string;
  region_id: number;
  region?: Region;
}

interface Parish {
  id: number;
  name: string;
  presbytery_id: number;
  presbytery?: Presbytery;
  created_at?: string;
}

interface Paginated<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

// --- Main Component ---

const ParishesPage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const token = useMemo(() => (typeof window !== 'undefined' ? localStorage.getItem('token') : null), []);

  // State
  const [query, setQuery] = useState('');
  const [selectedRegionId, setSelectedRegionId] = useState<string>('');
  const [selectedPresbyteryId, setSelectedPresbyteryId] = useState<string>('');
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [isFirstLoad, setIsFirstLoad] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Data
  const [parishes, setParishes] = useState<Parish[]>([]);
  const [regions, setRegions] = useState<Region[]>([]);
  const [presbyteries, setPresbyteries] = useState<Presbytery[]>([]);
  const [total, setTotal] = useState(0);

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Parish | null>(null);
  const [name, setName] = useState('');
  const [presbyteryId, setPresbyteryId] = useState<number | null>(null);
  const [modalRegionId, setModalRegionId] = useState<number | null>(null);
  const [modalPresbyteries, setModalPresbyteries] = useState<Presbytery[]>([]); // Presbyteries specific to modal selection
  const [saving, setSaving] = useState(false);

  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token]);

  // --- Fetchers ---

  const fetchRegions = async () => {
    try {
      const res = await axios.get(`${API_URL}/admin/regions?per_page=1000`, { headers });
      setRegions(res.data.data || []);
    } catch (e) {
      console.error('Failed to load regions', e);
    }
  };

  const fetchPresbyteries = async (regionId?: number, forModal = false) => {
    try {
      const url = regionId
        ? `${API_URL}/admin/presbyteries?region_id=${regionId}&per_page=1000`
        : `${API_URL}/admin/presbyteries?per_page=1000`;
      const res = await axios.get(url, { headers });
      
      if (forModal) {
        setModalPresbyteries(res.data.data || []);
      } else {
        setPresbyteries(res.data.data || []);
      }
    } catch (e) {
      console.error('Failed to load presbyteries', e);
    }
  };

  const fetchParishes = async () => {
    if (!token) { setError('Not authenticated'); setLoading(false); return; }
    setLoading(true); setError(null);
    try {
      const params = new URLSearchParams({
        q: query,
        page: String(page),
        per_page: String(perPage),
      });
      if (selectedRegionId) params.append('region_id', selectedRegionId);
      if (selectedPresbyteryId) params.append('presbytery_id', selectedPresbyteryId);
      
      const res = await axios.get<Paginated<Parish>>(`${API_URL}/admin/parishes?${params.toString()}`, { headers });
      setParishes(res.data.data);
      setTotal(res.data.total);
    } catch (e: any) {
      setError(e?.response?.data?.message || 'Failed to load parishes');
    } finally {
      setLoading(false);
      if (isFirstLoad) setIsFirstLoad(false);
    }
  };

  // --- Effects ---

  useEffect(() => {
    fetchRegions();
    fetchPresbyteries(); // Load all initially for filter
  }, []);

  // Filter Logic: When Region Filter changes, update Presbytery Filter list
  useEffect(() => {
    if (selectedRegionId) {
      fetchPresbyteries(Number(selectedRegionId));
    } else {
      fetchPresbyteries();
    }
    setSelectedPresbyteryId('');
  }, [selectedRegionId]);

  // Debounced Search / Filter Trigger
  useEffect(() => {
    const timeout = setTimeout(() => { setPage(1); fetchParishes(); }, 300);
    return () => clearTimeout(timeout);
  }, [query, selectedRegionId, selectedPresbyteryId]);

  // Pagination Trigger
  useEffect(() => { fetchParishes(); }, [page, perPage]);

  // --- Form Handlers ---

  const resetForm = () => {
    setEditing(null);
    setName('');
    setPresbyteryId(null);
    setModalRegionId(null);
    setModalPresbyteries([]);
    setSaving(false);
    setError(null);
  };

  const openCreate = () => { resetForm(); setModalOpen(true); };

  const openEdit = (parish: Parish) => {
    setEditing(parish);
    setName(parish.name);
    setPresbyteryId(parish.presbytery_id);
    
    const rId = parish.presbytery?.region_id || null;
    setModalRegionId(rId);
    
    if (rId) {
      fetchPresbyteries(rId, true); 
    } else {
      
      fetchPresbyteries(undefined, true);
    }
    setModalOpen(true);
  };

  const handleModalRegionChange = (rId: number | null) => {
    setModalRegionId(rId);
    setPresbyteryId(null);
    if (rId) {
      fetchPresbyteries(rId, true);
    } else {
      setModalPresbyteries([]);
    }
  };

  const saveParish = async () => {
    if (!name.trim()) { Swal.fire({ icon: 'warning', text: 'Parish name is required.' }); return; }
    if (!presbyteryId) { Swal.fire({ icon: 'warning', text: 'Presbytery is required.' }); return; }

    setSaving(true);
    try {
      if (editing) {
        await axios.put(`${API_URL}/admin/parishes/${editing.id}`, { name: name.trim(), presbytery_id: presbyteryId }, { headers });
      } else {
        await axios.post(`${API_URL}/admin/parishes`, { name: name.trim(), presbytery_id: presbyteryId }, { headers });
      }
      setModalOpen(false); resetForm(); fetchParishes();
      Swal.fire({ icon: 'success', title: 'Success', text: 'Parish saved successfully!', timer: 1500, showConfirmButton: false });
    } catch (e: any) {
      Swal.fire({ icon: 'error', title: 'Error', text: e?.response?.data?.message || 'Failed to save parish.' });
    } finally {
      setSaving(false);
    }
  };

  const deleteParish = async (parish: Parish) => {
    const result = await Swal.fire({
      title: 'Delete Parish?',
      text: "Are you sure you want to delete this parish? This action cannot be undone.",
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#1e3a8a',
      cancelButtonColor: '#94a3b8',
      confirmButtonText: 'Yes, delete it!'
    });

    if (result.isConfirmed) {
      try {
        await axios.delete(`${API_URL}/admin/parishes/${parish.id}`, { headers });
        fetchParishes();
        Swal.fire({ icon: 'success', title: 'Deleted!', text: 'Parish has been deleted.', timer: 1500, showConfirmButton: false });
      } catch (e: any) {
        Swal.fire({ icon: 'error', title: 'Error', text: 'Failed to delete parish.' });
      }
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  // --- LOADING STATE ---
  if (isFirstLoad && loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50">
        <DashboardLoader title="Loading Parishes" subtitle="Fetching local church assemblies..." />
      </div>
    );
  }

  return (
    <div className="p-6 md:p-8 min-h-screen bg-slate-50/50 font-sans text-slate-900">
      
      {/* --- Header --- */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
          <div className="flex items-center gap-3 mb-1">
            <div className="p-2.5 bg-blue-950 text-white rounded-xl shadow-sm">
              <Church className="w-6 h-6" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">Parishes</h1>
          </div>
          <p className="text-slate-500 text-sm ml-1">Manage local church assemblies</p>
        </motion.div>

        <motion.button 
          initial={{ opacity: 0 }} animate={{ opacity: 1 }}
          onClick={openCreate} 
          className="flex items-center gap-2 px-5 py-2.5 bg-blue-900 text-white text-sm font-bold rounded-xl hover:bg-blue-800 shadow-lg shadow-blue-900/20 transition-all active:scale-95"
        >
          <Plus className="w-5 h-5" /> 
          New Parish
        </motion.button>
      </div>

      {/* --- Toolbar --- */}
      <div className="bg-white p-2 rounded-2xl border border-slate-200 shadow-sm mb-6 flex flex-col md:flex-row items-center gap-2">
        {/* Search */}
        <div className="relative flex-1 w-full">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search parishes..."
            className="w-full pl-10 pr-4 py-2.5 bg-transparent rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:bg-slate-50 transition-colors text-slate-700"
          />
        </div>

        <div className="h-8 w-[1px] bg-slate-200 hidden md:block" />

        {/* Filters Container */}
        <div className="flex gap-2 w-full md:w-auto overflow-x-auto">
           {/* Region Filter */}
           <div className="relative min-w-[180px]">
              <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
              <select
                value={selectedRegionId}
                onChange={(e) => setSelectedRegionId(e.target.value)}
                className="w-full pl-9 pr-8 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-600 focus:outline-none focus:border-blue-500 appearance-none cursor-pointer hover:bg-slate-100 transition-colors"
              >
                <option value="">All Regions</option>
                {regions.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
              </select>
           </div>

           {/* Presbytery Filter */}
           <div className="relative min-w-[180px]">
              <Building2 className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
              <select
                value={selectedPresbyteryId}
                onChange={(e) => setSelectedPresbyteryId(e.target.value)}
                className="w-full pl-9 pr-8 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-600 focus:outline-none focus:border-blue-500 appearance-none cursor-pointer hover:bg-slate-100 transition-colors disabled:opacity-50"
                disabled={!selectedRegionId && presbyteries.length > 50} // Optional UX: force region select if too many presbyteries
              >
                <option value="">All Presbyteries</option>
                {presbyteries.map((p) => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </select>
           </div>
        </div>
      </div>

      {/* --- Error State --- */}
      {error && (
         <div className="mb-6 p-4 rounded-xl bg-red-50 border border-red-100 text-red-600 text-sm font-medium flex items-center gap-2">
           <AlertTriangle className="w-4 h-4" />
           {error}
         </div>
      )}

      {/* --- Table Content --- */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200">
                <th className="px-6 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Parish Name</th>
                <th className="px-6 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Presbytery</th>
                <th className="px-6 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Region</th>
                <th className="px-6 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading && !isFirstLoad ? (
                // Skeleton Rows
                [...Array(5)].map((_, i) => (
                  <tr key={i}>
                    <td colSpan={4} className="px-6 py-4">
                      <div className="h-4 bg-slate-100 rounded w-full animate-pulse"></div>
                    </td>
                  </tr>
                ))
              ) : parishes.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center">
                    <div className="w-12 h-12 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-3">
                      <Search className="w-6 h-6 text-slate-400" />
                    </div>
                    <h3 className="text-slate-900 font-medium text-sm">No parishes found</h3>
                    <p className="text-slate-500 text-xs mt-1">Try adjusting your search or filters.</p>
                  </td>
                </tr>
              ) : (
                <AnimatePresence mode="popLayout">
                  {parishes.map((parish) => (
                    <motion.tr
                      key={parish.id}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="group hover:bg-slate-50/80 transition-colors"
                    >
                      {/* Name Column */}
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="p-2 bg-blue-50 text-blue-900 rounded-lg">
                             <Church className="w-4 h-4" />
                          </div>
                          <span className="font-bold text-slate-900 text-sm">{parish.name}</span>
                        </div>
                      </td>

                      {/* Presbytery Column */}
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2 text-sm text-slate-600">
                          <Building2 className="w-3.5 h-3.5 text-slate-400" />
                          {parish.presbytery?.name || 'N/A'}
                        </div>
                      </td>

                      {/* Region Column */}
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2 text-sm text-slate-600">
                           <MapPin className="w-3.5 h-3.5 text-slate-400" />
                           {parish.presbytery?.region?.name || 'N/A'}
                        </div>
                      </td>

                      {/* Actions Column */}
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button 
                            onClick={() => openEdit(parish)}
                            className="p-2 hover:bg-white border border-transparent hover:border-slate-200 rounded-lg text-slate-500 hover:text-blue-600 transition-all shadow-sm"
                            title="Edit"
                          >
                            <Edit3 className="w-4 h-4" />
                          </button>
                          <button 
                            onClick={() => deleteParish(parish)}
                            className="p-2 hover:bg-red-50 border border-transparent hover:border-red-100 rounded-lg text-slate-500 hover:text-red-600 transition-all shadow-sm"
                            title="Delete"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              )}
            </tbody>
          </table>
        </div>

        {/* --- Pagination --- */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-slate-200 bg-slate-50/50">
           <div className="text-xs text-slate-500 font-medium">
              Showing <span className="text-slate-900 font-bold">{parishes.length}</span> of <span className="text-slate-900 font-bold">{total}</span> parishes
           </div>
           
           <div className="flex items-center gap-2">
              <select
                value={perPage}
                onChange={(e) => setPerPage(Number(e.target.value))}
                className="bg-transparent border-none text-xs font-medium text-slate-500 focus:ring-0 cursor-pointer mr-2"
              >
                <option value={10}>10 / page</option>
                <option value={20}>20 / page</option>
                <option value={50}>50 / page</option>
              </select>

              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page <= 1}
                className="p-2 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm"
              >
                 <ChevronLeft className="w-4 h-4 text-slate-600" />
              </button>
              <span className="px-4 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-bold text-slate-700 shadow-sm">
                 {page}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
                className="p-2 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm"
              >
                 <ChevronRight className="w-4 h-4 text-slate-600" />
              </button>
           </div>
        </div>
      </div>

      {/* --- Modal --- */}
      <AnimatePresence>
        {modalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              onClick={() => setModalOpen(false)}
              className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"
            />
            
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }} 
              animate={{ scale: 1, opacity: 1, y: 0 }} 
              exit={{ scale: 0.95, opacity: 0, y: 10 }}
              className="relative w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden"
            >
              <div className="bg-slate-50 px-6 py-4 border-b border-slate-100 flex justify-between items-center">
                <h2 className="font-bold text-slate-900 text-lg">{editing ? 'Edit Parish' : 'New Parish'}</h2>
                <button onClick={() => setModalOpen(false)} className="p-1 hover:bg-slate-200 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>
              
              <div className="p-6 space-y-4">
                
                {/* Region Select (Context for Presbytery) */}
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Region</label>
                  <div className="relative">
                    <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                    <select
                      value={modalRegionId || ''}
                      onChange={(e) => handleModalRegionChange(e.target.value ? Number(e.target.value) : null)}
                      className="w-full pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-900/20 focus:border-blue-900 outline-none transition-all text-slate-900 appearance-none cursor-pointer"
                    >
                      <option value="">Select Region (Filter Presbyteries)</option>
                      {regions.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
                    </select>
                  </div>
                </div>

                {/* Presbytery Select */}
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Presbytery <span className="text-red-500">*</span></label>
                  <div className="relative">
                    <Building2 className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                    <select
                      value={presbyteryId || ''}
                      onChange={(e) => setPresbyteryId(e.target.value ? Number(e.target.value) : null)}
                      className="w-full pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-900/20 focus:border-blue-900 outline-none transition-all text-slate-900 appearance-none cursor-pointer disabled:bg-slate-50 disabled:text-slate-400"
                      disabled={modalPresbyteries.length === 0 && !presbyteryId}
                    >
                      <option value="">Select Presbytery...</option>
                      {modalPresbyteries.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
                    </select>
                  </div>
                  {editing && <p className="text-[10px] text-slate-400 mt-1 ml-1">Can change presbytery assignment.</p>}
                </div>

                {/* Name Input */}
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Parish Name <span className="text-red-500">*</span></label>
                  <div className="relative">
                    <Church className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                    <input 
                      value={name} 
                      onChange={(e) => setName(e.target.value)} 
                      className="w-full pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-900/20 focus:border-blue-900 outline-none transition-all font-medium text-slate-900"
                      placeholder="e.g., St. Peter's Parish"
                      onKeyDown={(e) => e.key === 'Enter' && saveParish()}
                    />
                  </div>
                </div>

              </div>

              <div className="p-6 border-t border-slate-100 bg-slate-50/50 flex justify-end gap-3">
                <button 
                  onClick={() => setModalOpen(false)} 
                  className="px-5 py-2.5 text-sm font-bold text-slate-600 hover:bg-slate-200 rounded-xl transition-colors"
                >
                  Cancel
                </button>
                <button 
                  onClick={saveParish} 
                  disabled={saving || !name.trim() || !presbyteryId}
                  className="px-6 py-2.5 text-sm font-bold text-white bg-blue-900 hover:bg-blue-800 rounded-xl shadow-lg shadow-blue-900/20 transition-all active:scale-95 disabled:opacity-70 disabled:cursor-not-allowed flex items-center gap-2"
                >
                  {saving && <Loader2 className="w-4 h-4 animate-spin" />}
                  {saving ? 'Saving...' : 'Save Parish'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
};

export default ParishesPage;