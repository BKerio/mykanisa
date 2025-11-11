import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import Swal from "sweetalert2";
import "sweetalert2/dist/sweetalert2.min.css";
import {
  Loader2,
  Search,
  ChevronLeft,
  ChevronRight,
  Users,
  RefreshCw,
} from "lucide-react";
import { motion } from "framer-motion";

interface MemberDto {
  id: number;
  full_name: string;
  e_kanisa_number?: string;
  role?: string;
  marital_status?: string;
  groups?: string[] | string;
  group_names?: string[];
  region?: string;
  presbytery?: string;
  parish?: string;
  district?: string;
  congregation: string;
  telephone?: string;
  email?: string;
}

interface PaginatedResponse<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

const MembersPage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [rows, setRows] = useState<MemberDto[]>([]);
  const [total, setTotal] = useState(0);

  const roles = [
    "member",
    "deacon",
    "elder",
    "pastor",
    "secretary",
    "treasurer",
    "choir_leader",
    "youth_leader",
    "chairman",
    "sunday_school_teacher",
  ];

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("token") : null),
    []
  );

  const fetchMembers = async () => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const url = `${API_URL}/admin/members?q=${encodeURIComponent(
        query
      )}&page=${page}&per_page=${perPage}`;
      const res = await axios.get<PaginatedResponse<MemberDto>>(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setRows(res.data.data);
      setTotal(res.data.total);
    } catch (e: any) {
      setError(
        e?.response?.data?.message || e?.message || "Failed to load members"
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const handler = setTimeout(() => fetchMembers(), 300);
    return () => clearTimeout(handler);
  }, [query, page, perPage]);

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  const updateRole = async (member: MemberDto, newRole: string) => {
    if (!token) return;
    const prevRole = member.role || "member";
    try {
      const confirm = await Swal.fire({
        title: "Confirm Role Update",
        text: `Make ${member.full_name} a ${newRole}?`,
        icon: "question",
        showCancelButton: true,
        confirmButtonText: "Yes, update",
        cancelButtonText: "Cancel",
        background: "#f9fafb",
        customClass: {
          confirmButton:
            "bg-blue-600 text-white px-5 py-2 rounded-lg hover:bg-blue-700",
          cancelButton:
            "bg-gray-200 text-gray-800 px-5 py-2 rounded-lg hover:bg-gray-300",
        },
        buttonsStyling: false,
      });

      if (!confirm.isConfirmed) return;

      await axios.put(
        `${API_URL}/admin/members/${member.id}`,
        { role: newRole },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setRows((prev) =>
        prev.map((r) => (r.id === member.id ? { ...r, role: newRole } : r))
      );
      Swal.fire({
        toast: true,
        icon: "success",
        title: `Updated to "${newRole}"`,
        timer: 2000,
        showConfirmButton: false,
        position: "top-end",
      });
    } catch {
      setRows((prev) =>
        prev.map((r) => (r.id === member.id ? { ...r, role: prevRole } : r))
      );
    }
  };

  // ========== UI ==========
  if (loading && rows.length === 0)
    return (
      <div className="flex flex-col items-center justify-center min-h-[80vh] bg-gradient-to-br from-blue-50 to-white">
        <Loader2 className="w-14 h-14 text-blue-600 animate-spin" />
        <p className="mt-3 text-slate-600 text-lg">Loading members...</p>
      </div>
    );

  return (
    <div className="p-8 bg-gradient-to-b from-slate-50 to-white min-h-screen">
      {/* Header */}
      <div className="flex flex-wrap justify-between items-center mb-8">
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center gap-3"
        >
          <div className="bg-blue-100 p-2 rounded-xl">
            <Users className="w-7 h-7 text-blue-700" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-slate-800">
              Church Members
            </h1>
            <p className="text-slate-500 text-sm">
              Manage and update church member roles
            </p>
          </div>
        </motion.div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-2.5 text-slate-400 w-5 h-5" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search name, phone, or e-Kanisa..."
              className="pl-10 pr-4 py-2 w-80 border border-slate-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-400 bg-white transition"
            />
          </div>
          <button
            onClick={fetchMembers}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            <RefreshCw className="w-4 h-4" /> Refresh
          </button>
        </div>
      </div>

      {/* Data Table */}
      <div className="overflow-x-auto bg-white rounded-xl shadow-md border border-slate-200">
        <table className="min-w-full border-separate border-spacing-y-1">
          <thead className="sticky top-0 bg-blue-50 text-slate-700 text-xs uppercase tracking-wide">
            <tr>
              {[
                "Name",
                "My Kanisa No.",
                "Role",
                "Groups",
                "Region",
                "District",
                "Congregation",
                "Phone",
                "Email",
              ].map((header) => (
                <th
                  key={header}
                  className="px-5 py-3 text-left font-semibold border-b border-slate-200"
                >
                  {header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [...Array(perPage)].map((_, i) => (
                <tr key={i} className="animate-pulse">
                  <td className="p-5 bg-slate-50 rounded-lg" colSpan={9}>
                    <div className="h-4 bg-slate-200 rounded w-1/2"></div>
                  </td>
                </tr>
              ))
            ) : rows.length > 0 ? (
              rows.map((m, i) => (
                <motion.tr
                  key={m.id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: i * 0.02 }}
                  className="bg-white even:bg-slate-50 hover:bg-blue-50/60 transition-all rounded-lg shadow-sm border border-slate-100"
                >
                  <td className="px-5 py-3 text-slate-800 font-medium whitespace-nowrap">
                    {m.full_name}
                  </td>
                  <td className="px-5 py-3 text-slate-600">
                    {m.e_kanisa_number || "-"}
                  </td>
                  <td className="px-5 py-3">
                    <select
                      value={m.role || "member"}
                      onChange={(e) => updateRole(m, e.target.value)}
                      className="text-sm border border-slate-300 rounded-md px-2 py-1 bg-slate-50 text-slate-700 focus:ring-1 focus:ring-blue-400"
                    >
                      {roles.map((r) => (
                        <option key={r} value={r}>
                          {r}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td className="px-5 py-3">
                    {m.group_names?.length ? (
                      <div className="flex flex-wrap gap-2">
                        {m.group_names.map((g, i) => (
                          <span
                            key={i}
                            className="px-2.5 py-0.5 text-xs rounded-full bg-blue-100 text-blue-800 border border-blue-200"
                          >
                            {g}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <span className="text-slate-400 text-sm">—</span>
                    )}
                  </td>
                  <td className="px-5 py-3 text-slate-600">{m.region || "-"}</td>
                  <td className="px-5 py-3 text-slate-600">
                    {m.district || "-"}
                  </td>
                  <td className="px-5 py-3 text-slate-600">
                    {m.congregation}
                  </td>
                  <td className="px-5 py-3 text-slate-600">
                    {m.telephone || "-"}
                  </td>
                  <td className="px-5 py-3 text-slate-600">{m.email || "-"}</td>
                </motion.tr>
              ))
            ) : (
              <tr>
                <td
                  colSpan={9}
                  className="text-center py-10 text-slate-500 italic bg-white rounded-lg"
                >
                  No members found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex flex-wrap justify-between items-center mt-8 text-sm text-slate-700">
        <div className="flex items-center gap-2">
          <span>Rows per page:</span>
          <select
            value={perPage}
            onChange={(e) => {
              setPerPage(Number(e.target.value));
              setPage(1);
            }}
            className="border rounded-md px-2 py-1 bg-white shadow-sm"
          >
            {[10, 20, 50].map((n) => (
              <option key={n} value={n}>
                {n}
              </option>
            ))}
          </select>
        </div>

        <div className="flex items-center gap-3">
          <span>
            Page {page} of {totalPages}
          </span>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1 || loading}
              className="p-2 border rounded-lg disabled:opacity-50 bg-white hover:bg-slate-100 transition shadow-sm"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages || loading}
              className="p-2 border rounded-lg disabled:opacity-50 bg-white hover:bg-slate-100 transition shadow-sm"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {error && (
        <p className="text-red-600 mt-6 text-center font-medium bg-red-50 py-3 rounded-lg border border-red-200">
          {error}
        </p>
      )}
    </div>
  );
};

export default MembersPage;
