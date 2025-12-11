import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import {
    Search,
    ChevronLeft,
    ChevronRight,
    Activity,
    RefreshCw,
    Loader2,
    Calendar,
    Monitor,
    Download,
    Clock
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import DashboardLoader from "@/lib/loader";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

// --- Types ---
interface AuditLogDto {
    id: number;
    user_id: number | null;
    action: string;
    model_type: string | null;
    model_id: number | null;
    description: string;
    details: any;
    ip_address: string;
    user_agent: string;
    created_at: string;
    formatted_date: string;
    user?: {
        id: number;
        name: string;
        email: string;
        member?: {
            full_name: string;
            e_kanisa_number: string;
        }
    };
}

interface PaginatedResponse<T> {
    data: T[];
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
}

// --- Helpers ---
const getActionColor = (action: string) => {
    const a = action.toLowerCase();
    if (a.includes('create') || a.includes('add')) return "bg-green-100 text-green-800 border-green-200";
    if (a.includes('update') || a.includes('edit')) return "bg-blue-100 text-blue-800 border-blue-200";
    if (a.includes('delete') || a.includes('remove')) return "bg-red-100 text-red-800 border-red-200";
    if (a.includes('login')) return "bg-purple-100 text-purple-800 border-purple-200";
    return "bg-slate-100 text-slate-800 border-slate-200";
};

// --- Main Component ---
const AuditLogsPage = () => {
    const API_URL = import.meta.env.VITE_API_URL;
    const [query, setQuery] = useState("");
    const [page, setPage] = useState(1);
    const [perPage, setPerPage] = useState(20);
    const [loading, setLoading] = useState(true);
    const [logs, setLogs] = useState<AuditLogDto[]>([]);
    const [total, setTotal] = useState(0);
    const [isFirstLoad, setIsFirstLoad] = useState(true);

    const token = useMemo(() => (typeof window !== "undefined" ? localStorage.getItem("token") : null), []);

    const fetchLogs = async () => {
        if (!token) return;
        setLoading(true);
        try {
            const url = `${API_URL}/admin/audit-logs?search=${encodeURIComponent(query)}&page=${page}&per_page=${perPage}`;
            const res = await axios.get<PaginatedResponse<AuditLogDto>>(url, {
                headers: { Authorization: `Bearer ${token}` },
            });
            console.log("Logs response:", res.data);

            // Fix: API returns { status: 200, data: { data: [], total: ... } }
            const responseData = res.data as any;
            const pagination = responseData.data;

            // Extract array from pagination object
            const logsArray = Array.isArray(pagination) ? pagination : (pagination?.data || []);

            setLogs(logsArray);
            setTotal(pagination?.total || logsArray.length);
        } catch (e) {
            console.error("Fetch Error", e);
        } finally {
            setLoading(false);
            if (isFirstLoad) setIsFirstLoad(false);
        }
    };

    useEffect(() => {
        const handler = setTimeout(() => fetchLogs(), 400);
        return () => clearTimeout(handler);
    }, [query, page, perPage]);

    // Auto-refresh every 30 seconds
    useEffect(() => {
        const interval = setInterval(() => {
            if (!loading) fetchLogs();
        }, 30000);
        return () => clearInterval(interval);
    }, [loading, query, page, perPage]); // Refresh based on current view params

    const exportPDF = () => {
        const doc = new jsPDF();

        doc.setFontSize(18);
        doc.text("System Audit Logs", 14, 22);

        doc.setFontSize(11);
        doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 30);

        const tableColumn = ["Date", "User", "Action", "Description", "IP / Agent"];
        const tableRows = logs.map(log => [
            new Date(log.created_at).toLocaleString(),
            log.user?.member?.full_name || log.user?.name || "System \n" + (log.user?.email || ""),
            log.action,
            log.description,
            `${log.ip_address}\n${log.user_agent.substring(0, 30)}...`
        ]);

        autoTable(doc, {
            head: [tableColumn],
            body: tableRows,
            startY: 40,
            styles: { fontSize: 8 },
            headStyles: { fillColor: [30, 58, 138] }, // Blue-950
        });

        doc.save(`Audit_Logs_${new Date().toISOString().slice(0, 10)}.pdf`);
    };

    const totalPages = Math.max(1, Math.ceil(total / perPage));

    if (isFirstLoad && loading) {
        return (
            <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50">
                <DashboardLoader title="Loading Logs" subtitle="Fetching system activity..." />
            </div>
        );
    }

    return (
        <div className="p-6 md:p-10 bg-slate-50 min-h-screen font-sans text-slate-900">

            {/* Header */}
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-10 gap-4">
                <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
                    <div className="flex items-center gap-3 mb-1">
                        <div className="p-2.5 bg-blue-950 text-white rounded-xl shadow-sm">
                            <Activity className="w-6 h-6" />
                        </div>
                        <h1 className="text-2xl font-bold tracking-tight text-slate-900">System Audit Logs</h1>
                    </div>
                    <p className="text-slate-500 text-sm ml-1">Track all system activities and changes</p>
                </motion.div>

                <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto items-center">
                    <div className="flex items-center gap-2 text-xs text-slate-400 mr-2 bg-slate-100 px-3 py-1.5 rounded-full">
                        <Clock className="w-3. h-3" />
                        <span>Auto-refresh: 30s</span>
                    </div>

                    <div className="relative group w-full sm:w-auto">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4 group-focus-within:text-blue-900 transition-colors" />
                        <input
                            value={query}
                            onChange={(e) => setQuery(e.target.value)}
                            placeholder="Search logs..."
                            className="pl-10 pr-4 py-2.5 w-full sm:w-64 bg-white border border-slate-300 rounded-xl shadow-sm focus:ring-2 focus:ring-blue-900/20 focus:border-blue-900 transition-all outline-none text-slate-700"
                        />
                    </div>

                    <div className="flex gap-2">
                        <button
                            onClick={exportPDF}
                            title="Export to PDF"
                            className="flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50 hover:border-blue-900 hover:text-blue-900 transition-all shadow-sm active:scale-95"
                        >
                            <Download className="w-4 h-4" />
                            <span className="hidden sm:inline">Export</span>
                        </button>
                        <button
                            onClick={fetchLogs}
                            title="Refresh Now"
                            className="flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50 hover:border-blue-900 hover:text-blue-900 transition-all shadow-sm active:scale-95"
                        >
                            {loading ? <Loader2 className="w-4 h-4 animate-spin text-blue-900" /> : <RefreshCw className="w-4 h-4" />}
                        </button>
                    </div>
                </div>
            </div>

            {/* Table */}
            <div className="overflow-x-auto pb-4">
                <table className="min-w-full border-separate border-spacing-y-3">
                    <thead>
                        <tr className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                            <th className="px-4 pb-2 text-left">Date & Time</th>
                            <th className="px-4 pb-2 text-left">User</th>
                            <th className="px-4 pb-2 text-left">Action</th>
                            <th className="px-4 pb-2 text-left w-1/3">Description</th>
                            <th className="px-4 pb-2 text-left">Metadata</th>
                        </tr>
                    </thead>
                    <tbody className="relative">
                        {loading && !isFirstLoad ? (
                            [...Array(5)].map((_, i) => (
                                <tr key={i}>
                                    <td colSpan={5} className="px-4 py-2">
                                        <div className="h-16 bg-white rounded-2xl border border-slate-200 animate-pulse" />
                                    </td>
                                </tr>
                            ))
                        ) : (
                            <AnimatePresence mode="popLayout">
                                {logs.map((log, i) => (
                                    <motion.tr
                                        key={log.id}
                                        initial={{ opacity: 0, y: 10 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        transition={{ delay: i * 0.03 }}
                                        className="group bg-white rounded-2xl shadow-sm border border-slate-200 hover:shadow-md transition-all duration-300"
                                    >
                                        <td className="p-4 rounded-l-2xl whitespace-nowrap">
                                            <div className="flex items-center gap-2 text-sm font-medium text-slate-700">
                                                <Calendar className="w-3.5 h-3.5 text-slate-400" />
                                                {new Date(log.created_at).toLocaleString()}
                                            </div>
                                        </td>
                                        <td className="p-4">
                                            <div className="flex items-center gap-3">
                                                <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold text-slate-600">
                                                    {log.user?.name?.substring(0, 2).toUpperCase() || "SY"}
                                                </div>
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-bold text-slate-900">
                                                        {log.user?.member?.full_name || log.user?.name || "System"}
                                                    </span>
                                                    <span className="text-[10px] text-slate-500">
                                                        {log.user?.member?.e_kanisa_number
                                                            ? `#${log.user.member.e_kanisa_number}`
                                                            : log.user?.email}
                                                    </span>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="p-4">
                                            <span className={`px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide rounded-md border ${getActionColor(log.action)}`}>
                                                {log.action}
                                            </span>
                                        </td>
                                        <td className="p-4">
                                            <p className="text-sm text-slate-600 line-clamp-2" title={log.description}>
                                                {log.description}
                                            </p>
                                        </td>
                                        <td className="p-4 rounded-r-2xl">
                                            <div className="flex flex-col gap-1 text-[10px] text-slate-400 font-mono">
                                                <div className="flex items-center gap-1">
                                                    <Monitor className="w-3 h-3" />
                                                    {log.ip_address || "Unknown IP"}
                                                </div>
                                                <div className="truncate max-w-[100px]" title={log.user_agent}>
                                                    {log.user_agent}
                                                </div>
                                            </div>
                                        </td>
                                    </motion.tr>
                                ))}
                            </AnimatePresence>
                        )}
                    </tbody>
                </table>
                {!loading && logs.length === 0 && (
                    <div className="text-center py-20 text-slate-500">No audit logs found.</div>
                )}
            </div>

            {/* Pagination */}
            <div className="flex justify-between items-center mt-4">
                <div className="text-sm text-slate-500">Total: {total}</div>
                <div className="flex gap-2">
                    <button
                        onClick={() => setPage(p => Math.max(1, p - 1))}
                        disabled={page <= 1}
                        className="p-2 rounded bg-white border border-slate-300 hover:bg-slate-50 disabled:opacity-50"
                    >
                        <ChevronLeft className="w-4 h-4" />
                    </button>
                    <span className="px-3 py-2 text-sm font-bold bg-white border border-slate-300 rounded">{page}</span>
                    <button
                        onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                        disabled={page >= totalPages}
                        className="p-2 rounded bg-white border border-slate-300 hover:bg-slate-50 disabled:opacity-50"
                    >
                        <ChevronRight className="w-4 h-4" />
                    </button>
                </div>
            </div>
        </div>
    );
};

export default AuditLogsPage;
