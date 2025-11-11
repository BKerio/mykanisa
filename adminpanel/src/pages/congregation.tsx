import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import { Loader2, AlertTriangle, Building } from 'lucide-react';

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

const CongregationsPage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [congregations, setCongregations] = useState<CongregationDto[]>([]);
  const [total, setTotal] = useState(0);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("token") : null),
    []
  );

  const fetchCongregations = async () => {
    if (!token) {
      setError("Authentication token not found. Please log in.");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const url = `${API_URL}/admin/congregations?q=${encodeURIComponent(
        query
      )}&page=${page}&per_page=${perPage}`;
      const res = await axios.get<PaginatedResponse<CongregationDto>>(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCongregations(res.data.data);
      setTotal(res.data.total);
    } catch (e: any) {
      setError(
        e?.response?.data?.message || e?.message || "Failed to load congregations"
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Debounced search and fetch
    const handler = setTimeout(() => {
      setPage(1); // Reset to first page on new search
      fetchCongregations();
    }, 300);

    return () => clearTimeout(handler);
  }, [query]);

  useEffect(() => {
    // Fetch when page or perPage changes
    fetchCongregations();
  }, [page, perPage]);

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  // removed add congregation flow as per request

  // Initial full-page loader
  if (loading && congregations.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-200px)] bg-slate-50 p-4">
        <Loader2 className="w-16 h-16 text-green-600 animate-spin" />
        <p className="mt-4 text-lg text-slate-600 font-semibold">Loading congregations...</p>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 bg-slate-50 min-h-full">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-3xl font-bold text-slate-800">Congregations</h1>
        <div className="flex items-center gap-4">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search congregations..."
            className="border rounded-lg px-3 py-2 w-64 focus:ring-2 focus:ring-blue-300 focus:border-blue-500 transition"
          />
        </div>
      </div>
      
      {/* Error Display */}
      {error && !loading && (
        <div className="flex flex-col items-center justify-center p-8 bg-red-50 border border-red-200 rounded-lg">
           <AlertTriangle className="w-12 h-12 text-red-500" />
           <p className="mt-4 text-xl font-bold text-red-700">An Error Occurred</p>
           <p className="mt-2 text-slate-700">{error}</p>
        </div>
      )}

      {/* Table Card */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden border border-slate-200">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-slate-100 border-b border-slate-200">
              <tr className="text-left text-slate-700 font-semibold">
                <th className="p-3">Congregation Name</th>
                <th className="p-3">Parish</th>
                <th className="p-3">Presbytery</th>
                <th className="p-3">Member Count</th>
                <th className="p-3">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(perPage)].map((_, i) => (
                  <tr key={i} className="border-t animate-pulse">
                    <td className="p-3" colSpan={5}>
                      <div className="h-4 bg-slate-200 rounded w-full"></div>
                    </td>
                  </tr>
                ))
              ) : congregations.length > 0 ? (
                congregations.map((c) => (
                  <tr key={c.id} className="border-t border-slate-100 hover:bg-slate-50 transition-colors">
                    <td className="p-3 font-medium text-slate-800 flex items-center gap-2">
                        <Building size={16} className="text-slate-400" />
                        {c.name}
                    </td>
                    <td className="p-3 text-slate-600">{c.parish || "-"}</td>
                    <td className="p-3 text-slate-600">{c.presbytery || "-"}</td>
                    <td className="p-3 text-slate-600 font-medium">{c.member_count.toLocaleString()}</td>
                    <td className="p-3">
                      <button className="text-blue-600 hover:underline text-xs font-semibold">Edit</button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td className="p-8 text-center text-slate-500" colSpan={5}>
                    No congregations found. Try adjusting your search or adding a new one.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-2 text-sm text-slate-600">
          <span>Rows per page:</span>
          <select
            value={perPage}
            onChange={(e) => setPerPage(Number(e.target.value))}
            className="border rounded-md px-2 py-1 bg-white"
          >
            {[10, 20, 50].map((n) => <option key={n} value={n}>{n}</option>)}
          </select>
        </div>
        <div className="flex items-center gap-3 text-sm">
            <span className="text-slate-600">Page {page} of {totalPages}</span>
            <div className="flex items-center gap-1">
              <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page <= 1 || loading}
                  className="px-3 py-1 border rounded-lg disabled:opacity-50 disabled:cursor-not-allowed bg-white hover:bg-slate-50 transition"
              >
                  Prev
              </button>
              <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page >= totalPages || loading}
                  className="px-3 py-1 border rounded-lg disabled:opacity-50 disabled:cursor-not-allowed bg-white hover:bg-slate-50 transition"
              >
                  Next
              </button>
            </div>
        </div>
      </div>
    </div>
  );
};

export default CongregationsPage;