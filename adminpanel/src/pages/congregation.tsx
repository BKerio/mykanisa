import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import { 
  AlertTriangle, 
  Building2, 
  MapPin, 
  Users, 
  Search, 
  ChevronLeft, 
  ChevronRight, 
  MoreVertical,
  ArrowRight,
  RefreshCw,
  Loader2
} from 'lucide-react';
import { motion, AnimatePresence } from "framer-motion";
import DashboardLoader from "@/lib/loader"; // Adjust path as needed

// --- Types ---
interface CongregationDto {
  id: number;
  name: string;
  parish?: string;
  presbytery?: string;
  member_count: number;
}

interface PaginatedResponse<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

// --- Helpers ---
const getRandomColor = (id: number) => {
  // Strict Blue/Slate Palette for avatars
  const colors = [
    "bg-blue-900", 
    "bg-blue-700", 
    "bg-blue-600", 
    "bg-slate-700", 
    "bg-slate-800", 
    "bg-indigo-900"
  ];
  return colors[id % colors.length];
};

// --- Sub-Components ---

const CongregationCard = ({ data, index }: { data: CongregationDto; index: number }) => {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ delay: index * 0.05, duration: 0.3 }}
      className="group relative bg-white rounded-2xl border border-slate-200 p-5 shadow-sm hover:shadow-md hover:border-blue-300 transition-all duration-300"
    >
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-5">
        
        {/* Left: Identity & Name */}
        <div className="flex items-start gap-4">
          {/* Icon Avatar */}
          <div className={`w-12 h-12 rounded-xl shadow-sm ${getRandomColor(data.id)} flex items-center justify-center text-white shrink-0 group-hover:scale-105 transition-transform duration-300`}>
            <Building2 className="w-6 h-6" />
          </div>
          
          <div>
            <h3 className="text-lg font-bold text-slate-900 group-hover:text-blue-900 transition-colors">
              {data.name}
            </h3>
            
            {/* Hierarchy Breadcrumb */}
            <div className="flex items-center flex-wrap gap-2 mt-1 text-xs font-medium text-slate-500">
              <span className="flex items-center gap-1 bg-slate-50 px-2 py-0.5 rounded-md border border-slate-200 text-slate-600">
                <MapPin className="w-3 h-3 text-blue-900" />
                {data.presbytery || "No Presbytery"}
              </span>
              <ArrowRight className="w-3 h-3 text-slate-300" />
              <span className="text-slate-600">
                {data.parish || "No Parish"}
              </span>
            </div>
          </div>
        </div>

        {/* Right: Stats & Actions */}
        <div className="flex items-center justify-between md:justify-end gap-6 w-full md:w-auto border-t md:border-t-0 border-slate-100 pt-4 md:pt-0">
          
          {/* Member Count Badge */}
          <div className="flex items-center gap-3">
            <div className="text-right">
              <span className="block text-xs text-slate-400 font-bold uppercase tracking-wider">Population</span>
              <span className="text-lg font-bold text-slate-800 tabular-nums">{data.member_count.toLocaleString()}</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-900 border border-blue-100">
              <Users className="w-5 h-5" />
            </div>
          </div>

          {/* Action Button */}
          <div className="h-8 w-[1px] bg-slate-200 hidden md:block"></div>
          
          <button className="p-2 rounded-lg hover:bg-slate-100 text-slate-400 hover:text-blue-900 transition-colors">
            <MoreVertical className="w-5 h-5" />
          </button>
        </div>
      </div>
    </motion.div>
  );
};

// --- Main Component ---

const CongregationsPage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [congregations, setCongregations] = useState<CongregationDto[]>([]);
  const [total, setTotal] = useState(0);
  const [isFirstLoad, setIsFirstLoad] = useState(true);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("token") : null),
    []
  );

  const fetchCongregations = async () => {
    if (!token) {
      setError("Authentication token not found.");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const url = `${API_URL}/admin/congregations?q=${encodeURIComponent(query)}&page=${page}&per_page=${perPage}`;
      const res = await axios.get<PaginatedResponse<CongregationDto>>(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCongregations(res.data.data);
      setTotal(res.data.total);
    } catch (e: any) {
      setError(e?.response?.data?.message || e?.message || "Failed to load data");
    } finally {
      setLoading(false);
      if (isFirstLoad) setIsFirstLoad(false);
    }
  };

  useEffect(() => {
    const handler = setTimeout(() => {
      setPage(1);
      fetchCongregations();
    }, 400);
    return () => clearTimeout(handler);
  }, [query]);

  useEffect(() => {
    fetchCongregations();
  }, [page, perPage]);

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  // --- LOADING STATE ---
  if (isFirstLoad && loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50">
        <DashboardLoader 
          title="Loading Branches" 
          subtitle="Fetching congregation hierarchy and stats..." 
        />
      </div>
    );
  }

  return (
    <div className="p-6 md:p-8 min-h-screen bg-slate-50/50 font-sans text-slate-900">
      
      {/* --- Header Section --- */}
      <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 mb-10">
        <motion.div 
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className="flex items-center gap-3">
             <div className="bg-blue-950 p-2 rounded-xl shadow-sm">
                <Building2 className="w-6 h-6 text-white" />
             </div>
             <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Congregations</h1>
          </div>
          <p className="text-slate-500 text-sm mt-1 ml-1">Manage church branches and their populations</p>
        </motion.div>

        <div className="flex flex-col sm:flex-row gap-3 w-full lg:w-auto">
          {/* Search Input */}
          <div className="relative group">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-4 w-4 text-slate-400 group-focus-within:text-blue-900 transition-colors" />
            </div>
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search congregation..."
              className="block w-full sm:w-80 pl-10 pr-3 py-2.5 border border-slate-300 rounded-xl leading-5 bg-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-900/20 focus:border-blue-900 transition-all shadow-sm text-slate-700"
            />
          </div>
          
          <button 
            onClick={fetchCongregations}
            className="flex items-center justify-center px-4 py-2.5 border border-slate-300 bg-white rounded-xl text-slate-700 hover:bg-slate-50 hover:text-blue-900 hover:border-blue-900 transition-all shadow-sm active:scale-95"
          >
            {loading ? (
               <Loader2 className="h-4 w-4 animate-spin text-blue-900" />
            ) : (
               <RefreshCw className="h-4 w-4" />
            )}
          </button>
        </div>
      </div>

      {/* --- Error State --- */}
      {error && (
        <motion.div 
          initial={{ opacity: 0, height: 0 }} 
          animate={{ opacity: 1, height: 'auto' }}
          className="mb-6 p-4 rounded-xl bg-red-50 border border-red-100 flex items-center gap-3 text-red-700"
        >
          <AlertTriangle className="w-5 h-5 shrink-0" />
          <span className="text-sm font-medium">{error}</span>
        </motion.div>
      )}

      {/* --- Content Area --- */}
      <div className="space-y-4">
        {loading && !isFirstLoad ? (
          // Skeleton Loader (During filtering)
          [...Array(3)].map((_, i) => (
            <div key={i} className="h-28 w-full bg-white rounded-2xl border border-slate-200 animate-pulse shadow-sm flex p-5 gap-4">
               <div className="w-12 h-12 bg-slate-200 rounded-xl"></div>
               <div className="flex-1 space-y-2 py-2">
                  <div className="h-4 bg-slate-200 rounded w-1/3"></div>
                  <div className="h-3 bg-slate-200 rounded w-1/4"></div>
               </div>
            </div>
          ))
        ) : congregations.length > 0 ? (
          <AnimatePresence mode="popLayout">
            {congregations.map((congregation, index) => (
              <CongregationCard key={congregation.id} data={congregation} index={index} />
            ))}
          </AnimatePresence>
        ) : (
          // Empty State
          <motion.div 
            initial={{ opacity: 0 }} 
            animate={{ opacity: 1 }}
            className="flex flex-col items-center justify-center py-16 bg-white rounded-3xl border border-slate-200 border-dashed"
          >
            <div className="bg-slate-50 p-4 rounded-full mb-4">
              <Search className="w-8 h-8 text-slate-400" />
            </div>
            <h3 className="text-lg font-bold text-slate-700">No congregations found</h3>
            <p className="text-slate-500 text-sm mt-1 max-w-xs text-center">
              We couldn't find anything matching "{query}". Try a different search term.
            </p>
          </motion.div>
        )}
      </div>

      {/* --- Pagination Footer --- */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mt-8 px-2">
        <div className="text-sm text-slate-500">
          Showing <span className="font-bold text-slate-900">{congregations.length}</span> of <span className="font-bold text-slate-900">{total}</span> locations
        </div>

        <div className="flex items-center gap-4">
          <select
            value={perPage}
            onChange={(e) => setPerPage(Number(e.target.value))}
            className="bg-transparent border-none text-sm font-medium text-slate-600 focus:ring-0 cursor-pointer hover:text-blue-900 transition-colors"
          >
            <option value={10}>10 per page</option>
            <option value={20}>20 per page</option>
            <option value={50}>50 per page</option>
          </select>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1 || loading}
              className="p-2 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm"
            >
              <ChevronLeft className="w-4 h-4 text-slate-600" />
            </button>
            <div className="px-4 py-1 bg-white border border-slate-200 rounded-lg text-sm font-bold text-slate-700 shadow-sm">
              {page}
            </div>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages || loading}
              className="p-2 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm"
            >
              <ChevronRight className="w-4 h-4 text-slate-600" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CongregationsPage;