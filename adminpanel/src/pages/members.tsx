import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import Swal from "sweetalert2";
import "sweetalert2/dist/sweetalert2.min.css";
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Users,
  RefreshCw,
  MoreHorizontal,
  ShieldCheck,
  Mail,
  Phone,
  MapPin,
  Music,
  X,
  Layers,
  Loader2
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import DashboardLoader from "@/lib/loader"; // Adjust path as needed

// --- Types ---
interface MemberDto {
  id: number;
  full_name: string;
  e_kanisa_number?: string;
  role?: string;
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

// --- Helpers ---
// STRICT DARK BLUE THEME
const getGroupColor = (name: string) => {
  // Only shades of Blue and Slate
  const variants = [
    "bg-blue-50 text-blue-900 border-blue-200",
    "bg-slate-100 text-slate-800 border-slate-300",
    "bg-blue-100 text-blue-950 border-blue-300",
    "bg-slate-50 text-slate-900 border-slate-200",
  ];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return variants[Math.abs(hash) % variants.length];
};

const getGroupIcon = (name: string) => {
  const n = name.toLowerCase();
  if (n.includes("choir") || n.includes("worship")) return <Music className="w-3 h-3 mr-1.5" />;
  if (n.includes("youth") || n.includes("men") || n.includes("women")) return <Users className="w-3 h-3 mr-1.5" />;
  return <Layers className="w-3 h-3 mr-1.5" />;
};

// --- Sub-Components ---

// 1. Interactive Group Tags (Trigger)
const GroupTags = ({ groups, onClick }: { groups?: string[]; onClick: () => void }) => {
  if (!groups || groups.length === 0) {
    return <span className="text-slate-400 text-xs italic">No groups</span>;
  }

  const visibleGroups = groups.slice(0, 2);
  const hiddenCount = groups.length - 2;

  return (
    <div 
      onClick={onClick}
      className="flex flex-wrap items-center gap-2 cursor-pointer hover:bg-slate-100 p-2 -m-2 rounded-lg transition-colors group"
    >
      {visibleGroups.map((g, i) => (
        <span
          key={i}
          className={`flex items-center px-2.5 py-1 text-[11px] font-bold rounded-md border ${getGroupColor(g)}`}
        >
          {getGroupIcon(g)}
          {g}
        </span>
      ))}

      {hiddenCount > 0 && (
        <motion.div 
          whileHover={{ scale: 1.05 }}
          className="flex items-center justify-center px-2 py-1 rounded-md bg-blue-900 text-white text-[10px] font-bold border border-blue-800"
        >
          +{hiddenCount} more
        </motion.div>
      )}
    </div>
  );
};

// 2. Busted Animated Modal (The "Pop-out" Card)
const GroupDetailsModal = ({ member, onClose }: { member: MemberDto | null; onClose: () => void }) => {
  if (!member) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"
      />

      {/* Card */}
      <motion.div
        initial={{ scale: 0.8, opacity: 0, y: 20, rotateX: 10 }}
        animate={{ scale: 1, opacity: 1, y: 0, rotateX: 0 }}
        exit={{ scale: 0.9, opacity: 0, y: 20 }}
        transition={{ type: "spring", stiffness: 300, damping: 20 }}
        className="relative w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden border border-slate-200"
      >
        {/* Header (Dark Blue) */}
        <div className="bg-blue-950 p-6 text-white relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-5 transform translate-x-4 -translate-y-4">
             <Users size={120} />
          </div>
          
          <button 
            onClick={onClose}
            className="absolute top-4 right-4 p-2 bg-white/10 hover:bg-white/20 rounded-full transition-colors"
          >
            <X className="w-5 h-5 text-white" />
          </button>

          <h3 className="text-2xl font-bold relative z-10">{member.full_name}</h3>
          <p className="text-blue-200 text-sm mt-1 relative z-10 flex items-center gap-2">
            <ShieldCheck className="w-4 h-4" />
            {member.e_kanisa_number || "No ID"}
          </p>
        </div>

        {/* Body */}
        <div className="p-6 bg-slate-50 max-h-[60vh] overflow-y-auto">
          <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4 border-b border-slate-200 pb-2">
            Active Memberships ({member.group_names?.length || 0})
          </h4>
          
          <div className="space-y-3">
            {member.group_names && member.group_names.length > 0 ? (
              member.group_names.map((group, idx) => (
                <motion.div
                  key={idx}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: idx * 0.05 }}
                  className="flex items-center justify-between p-4 bg-white border border-slate-200 rounded-xl shadow-sm hover:border-blue-300 hover:shadow-md transition-all"
                >
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg bg-blue-50 text-blue-900`}>
                      {getGroupIcon(group)}
                    </div>
                    <span className="font-bold text-slate-800">{group}</span>
                  </div>
                  <div className="w-2 h-2 rounded-full bg-blue-900"></div>
                </motion.div>
              ))
            ) : (
              <div className="text-center py-8 text-slate-400">
                No groups assigned to this member.
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-200 bg-white text-center">
          <button 
            onClick={onClose}
            className="w-full py-3 bg-blue-950 text-white font-bold rounded-xl hover:bg-blue-900 transition-colors shadow-lg"
          >
            Close Details
          </button>
        </div>
      </motion.div>
    </div>
  );
};

// --- Main Component ---

const MembersPage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [rows, setRows] = useState<MemberDto[]>([]);
  const [total, setTotal] = useState(0);
  const [activeGroupMember, setActiveGroupMember] = useState<MemberDto | null>(null);
  const [isFirstLoad, setIsFirstLoad] = useState(true);

  const roles = ["member", "deacon", "elder", "pastor", "secretary", "treasurer", "choir_leader", "youth_leader", "chairman"];

  const token = useMemo(() => (typeof window !== "undefined" ? localStorage.getItem("token") : null), []);

  const fetchMembers = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const url = `${API_URL}/admin/members?q=${encodeURIComponent(query)}&page=${page}&per_page=${perPage}`;
      const res = await axios.get<PaginatedResponse<MemberDto>>(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setRows(res.data.data);
      setTotal(res.data.total);
    } catch (e) {
      console.error("Fetch Error", e);
    } finally {
      setLoading(false);
      if (isFirstLoad) setIsFirstLoad(false);
    }
  };

  useEffect(() => {
    const handler = setTimeout(() => fetchMembers(), 400);
    return () => clearTimeout(handler);
  }, [query, page, perPage]);

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  const updateRole = async (member: MemberDto, newRole: string) => {
    const prevRole = member.role || "member";
    const API_URL = import.meta.env.VITE_API_URL;
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
    const headers = { Authorization: `Bearer ${token}` };
    
    // If assigning youth_leader role, show group selection
    if (newRole === 'youth_leader') {
      try {
        // Fetch all groups
        const groupsRes = await axios.get(`${API_URL}/groups`, { headers });
        const groups = groupsRes.data?.groups || [];
        
        if (groups.length === 0) {
          Swal.fire({ 
            icon: "error", 
            title: "No Groups Available", 
            text: "Please create groups first before assigning youth leaders.",
            confirmButtonColor: "#172554"
          });
          return;
        }
        
        // Get member's group names from the member object
        const memberGroupNames = member.group_names || [];
        
        // Create options HTML for groups, highlighting which ones the member belongs to
        const groupOptions = groups.map((g: any) => {
          const isMember = memberGroupNames.includes(g.name);
          return `<option value="${g.id}" ${!isMember ? 'disabled' : ''}>${g.name}${!isMember ? ' (Not a member)' : ''}</option>`;
        }).join('');
        
        const result = await Swal.fire({
          title: `<span class="text-xl font-bold text-slate-800">Assign Youth Leader Role</span>`,
          html: `
            <p class="text-slate-600 mb-4">Change <b>${member.full_name}</b> to <span class="font-mono text-xs bg-blue-50 text-blue-900 p-1 rounded">${newRole}</span>?</p>
            <p class="text-xs text-slate-500 mb-3">Select the group this youth leader will be assigned to. The member must already be a member of the selected group.</p>
            <select id="group-select" class="swal2-input" style="display: block; width: 100%; padding: 0.5rem; margin-top: 0.5rem; border: 1px solid #cbd5e1; border-radius: 0.5rem;">
              <option value="">-- Select Group --</option>
              ${groupOptions}
            </select>
          `,
          icon: "question",
          showCancelButton: true,
          confirmButtonText: "Confirm Assignment",
          confirmButtonColor: "#172554",
          cancelButtonColor: "#94a3b8",
          background: "#fff",
          customClass: { popup: "rounded-2xl" },
          didOpen: () => {
            const select = document.getElementById('group-select') as HTMLSelectElement;
            if (select) {
              select.focus();
            }
          },
          preConfirm: () => {
            const select = document.getElementById('group-select') as HTMLSelectElement;
            const selectedGroupId = select?.value;
            if (!selectedGroupId) {
              Swal.showValidationMessage('Please select a group');
              return false;
            }
            return selectedGroupId;
          }
        });

        if (!result.isConfirmed || !result.value) return;

        const selectedGroupId = parseInt(result.value as string);
        
        // Verify member is part of selected group
        const selectedGroup = groups.find((g: any) => g.id === selectedGroupId);
        //const memberGroupNames = member.group_names || [];
        
        if (!selectedGroup || !memberGroupNames.includes(selectedGroup.name)) {
          Swal.fire({ 
            icon: "error", 
            title: "Validation Error", 
            text: `Member must be a member of "${selectedGroup?.name}" before being assigned as youth leader.`,
            confirmButtonColor: "#172554"
          });
          return;
        }

        // Update role with assigned group
        try {
          await axios.put(
            `${API_URL}/admin/members/${member.id}`, 
            { role: newRole, assigned_group_id: selectedGroupId }, 
            { headers }
          );
          setRows((prev) => prev.map((r) => (r.id === member.id ? { ...r, role: newRole } : r)));
          Swal.fire({ 
            icon: "success", 
            title: "Role Updated", 
            text: `${member.full_name} is now youth leader for ${selectedGroup?.name}`,
            timer: 2000, 
            showConfirmButton: false, 
            toast: true, 
            position: 'top-end' 
          });
        } catch (error: any) {
          Swal.fire({ 
            icon: "error", 
            title: "Update Failed", 
            text: error?.response?.data?.message || "Failed to update role. Member may not be part of selected group.",
            confirmButtonColor: "#172554"
          });
        }
      } catch (error: any) {
        Swal.fire({ 
          icon: "error", 
          title: "Error", 
          text: error?.response?.data?.message || "Failed to load groups",
          confirmButtonColor: "#172554"
        });
      }
    } else {
      // For other roles, use simple confirmation
      const confirm = await Swal.fire({
        title: `<span class="text-xl font-bold text-slate-800">Update Role?</span>`,
        html: `<p class="text-slate-600">Change <b>${member.full_name}</b> from <span class="font-mono text-xs bg-slate-100 p-1 rounded">${prevRole}</span> to <span class="font-mono text-xs bg-blue-50 text-blue-900 p-1 rounded">${newRole}</span>?</p>`,
        icon: "question",
        showCancelButton: true,
        confirmButtonText: "Confirm Change",
        confirmButtonColor: "#172554",
        cancelButtonColor: "#94a3b8",
        background: "#fff",
        customClass: { popup: "rounded-2xl" }
      });

      if (!confirm.isConfirmed) return;

      try {
        await axios.put(`${API_URL}/admin/members/${member.id}`, { role: newRole }, { headers });
        setRows((prev) => prev.map((r) => (r.id === member.id ? { ...r, role: newRole } : r)));
        Swal.fire({ icon: "success", title: "Role Updated", timer: 1500, showConfirmButton: false, toast: true, position: 'top-end' });
      } catch {
        // Revert on error
      }
    }
  };

  // --- INITIAL LOADING STATE ---
  if (isFirstLoad && loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50">
        <DashboardLoader 
          title="Loading Directory" 
          subtitle="Fetching member records..." 
        />
      </div>
    );
  }

  return (
    <div className="p-6 md:p-10 bg-slate-50 min-h-screen font-sans text-slate-900">
      
      {/* Modal for Groups */}
      <AnimatePresence>
        {activeGroupMember && (
          <GroupDetailsModal 
            member={activeGroupMember} 
            onClose={() => setActiveGroupMember(null)} 
          />
        )}
      </AnimatePresence>

      {/* --- Header Section --- */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-10 gap-4">
        <motion.div 
          initial={{ opacity: 0, x: -20 }} 
          animate={{ opacity: 1, x: 0 }}
        >
          <div className="flex items-center gap-3 mb-1">
            <div className="p-2.5 bg-blue-950 text-white rounded-xl shadow-sm">
              <Users className="w-6 h-6" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">Directory Management</h1>
          </div>
          <p className="text-slate-500 text-sm ml-1">View and manage congregation members</p>
        </motion.div>

        <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
          <div className="relative group">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4 group-focus-within:text-blue-900 transition-colors" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search members..."
              className="pl-10 pr-4 py-2.5 w-full sm:w-72 bg-white border border-slate-300 rounded-xl shadow-sm focus:ring-2 focus:ring-blue-900/20 focus:border-blue-900 transition-all outline-none text-slate-700"
            />
          </div>
          <button 
            onClick={fetchMembers}
            className="flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50 hover:border-blue-900 hover:text-blue-900 transition-all shadow-sm active:scale-95"
          >
            {loading ? (
              <Loader2 className="w-4 h-4 animate-spin text-blue-900" />
            ) : (
              <RefreshCw className="w-4 h-4" />
            )}
          </button>
        </div>
      </div>

      {/* --- Data Display --- */}
      <div className="overflow-x-auto pb-4">
        <table className="min-w-full border-separate border-spacing-y-3">
          <thead>
            <tr className="text-xs font-bold text-slate-500 uppercase tracking-wider">
              <th className="px-4 pb-2 text-left">Member Profile</th>
              <th className="px-4 pb-2 text-left">Role</th>
              <th className="px-4 pb-2 text-left w-64">Groups & Ministries</th>
              <th className="px-4 pb-2 text-left">Location</th>
              <th className="px-4 pb-2 text-left">Contact Infor</th>
            </tr>
          </thead>
          <tbody className="relative">
            {loading && !isFirstLoad ? (
              // Skeleton Loader (Used during filtering/pagination to prevent layout shift)
              [...Array(5)].map((_, i) => (
                <tr key={i}>
                  <td colSpan={5} className="px-4 py-2">
                    <div className="h-24 bg-white rounded-2xl border border-slate-200 p-4 flex items-center gap-4 shadow-sm">
                       <div className="w-10 h-10 bg-slate-200 rounded-full animate-pulse" />
                       <div className="flex-1 space-y-2">
                          <div className="h-4 bg-slate-200 rounded w-1/4 animate-pulse" />
                          <div className="h-3 bg-slate-200 rounded w-1/3 animate-pulse" />
                       </div>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <AnimatePresence mode="popLayout">
                {rows.map((m, i) => (
                  <motion.tr
                    key={m.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    transition={{ delay: i * 0.05 }}
                    className="group relative bg-white rounded-2xl shadow-sm border border-slate-200 hover:shadow-md hover:border-blue-900/30 transition-all duration-300"
                  >
                    {/* 1. Profile Column */}
                    <td className="p-4 rounded-l-2xl">
                      <div className="flex items-center gap-4">
                        <div className="relative">
                          <div className="w-10 h-10 rounded-full bg-blue-950 text-white flex items-center justify-center font-bold text-sm shadow-md">
                            {m.full_name.substring(0, 2).toUpperCase()}
                          </div>
                          {m.e_kanisa_number && (
                            <div className="absolute -bottom-1 -right-1 bg-white rounded-full p-0.5">
                              <div className="w-2.5 h-2.5 bg-blue-700 rounded-full border-2 border-white" />
                            </div>
                          )}
                        </div>
                        <div>
                          <div className="font-bold text-slate-900 text-[15px]">{m.full_name}</div>
                          <div className="text-xs text-slate-500 font-mono flex items-center gap-1">
                            <ShieldCheck className="w-3 h-3 text-blue-900" />
                            {m.e_kanisa_number || "N/A"}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* 2. Role Selector Column */}
                    <td className="p-4">
                      <div className="relative inline-block">
                        <select
                          value={m.role || "member"}
                          onChange={(e) => updateRole(m, e.target.value)}
                          className="appearance-none cursor-pointer pl-3 pr-8 py-1.5 text-xs font-bold uppercase tracking-wide rounded-lg bg-slate-50 text-slate-700 border border-slate-300 hover:border-blue-900 hover:bg-white hover:text-blue-900 transition-colors outline-none focus:ring-2 focus:ring-blue-900/20"
                        >
                          {roles.map((r) => (
                            <option key={r} value={r}>
                              {r.replace("_", " ")}
                            </option>
                          ))}
                        </select>
                        <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-slate-400">
                          <MoreHorizontal className="h-3 w-3" />
                        </div>
                      </div>
                    </td>

                    {/* 3. Interactive Groups Column */}
                    <td className="p-4">
                      <GroupTags 
                        groups={m.group_names} 
                        onClick={() => setActiveGroupMember(m)}
                      />
                    </td>

                    {/* 4. Location Column */}
                    <td className="p-4">
                      <div className="flex flex-col gap-1">
                        <div className="flex items-center text-xs font-medium text-slate-800">
                           <MapPin className="w-3 h-3 mr-1 text-slate-400" />
                           {m.congregation}
                        </div>
                        <div className="text-[11px] text-slate-500 pl-4">
                          {m.district || "No District"} • {m.region || "No Region"}
                        </div>
                      </div>
                    </td>

                    {/* 5. Contact Column */}
                    <td className="p-4 rounded-r-2xl">
                      <div className="flex flex-col gap-1.5">
                         <div className="flex items-center text-xs text-slate-600">
                            <Phone className="w-3 h-3 mr-2 text-slate-400" />
                            {m.telephone || "-"}
                         </div>
                         <div className="flex items-center text-xs text-slate-600">
                            <Mail className="w-3 h-3 mr-2 text-slate-400" />
                            <span className="truncate max-w-[120px]" title={m.email}>{m.email || "-"}</span>
                         </div>
                      </div>
                    </td>
                  </motion.tr>
                ))}
              </AnimatePresence>
            )}
          </tbody>
        </table>
        
        {!loading && rows.length === 0 && (
           <div className="text-center py-20">
             <div className="inline-flex p-4 rounded-full bg-slate-100 text-slate-400 mb-4">
               <Search className="w-8 h-8" />
             </div>
             <h3 className="text-lg font-medium text-slate-900">No members found</h3>
             <p className="text-slate-500 text-sm mt-1">Try adjusting your search or filters.</p>
           </div>
        )}
      </div>

      {/* --- Footer / Pagination --- */}
      <div className="flex flex-col sm:flex-row justify-between items-center gap-4 mt-2 px-2">
        <div className="text-sm text-slate-500 font-medium">
          Showing <span className="text-slate-900 font-bold">{rows.length}</span> of <span className="text-slate-900 font-bold">{total}</span> members
        </div>

        <div className="flex items-center gap-4">
          <select
            value={perPage}
            onChange={(e) => { setPerPage(Number(e.target.value)); setPage(1); }}
            className="bg-transparent text-sm font-medium text-slate-600 border-none focus:ring-0 cursor-pointer hover:text-blue-900"
          >
            <option value={10}>10 per page</option>
            <option value={20}>20 per page</option>
            <option value={50}>50 per page</option>
          </select>

          <div className="flex items-center gap-1 bg-white rounded-lg border border-slate-300 p-1 shadow-sm">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1 || loading}
              className="p-2 rounded-md hover:bg-slate-50 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
            >
              <ChevronLeft className="w-4 h-4 text-slate-700" />
            </button>
            <span className="px-3 text-sm font-bold text-slate-900">{page}</span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages || loading}
              className="p-2 rounded-md hover:bg-slate-50 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
            >
              <ChevronRight className="w-4 h-4 text-slate-700" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MembersPage;