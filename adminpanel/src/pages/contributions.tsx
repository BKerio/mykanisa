import { useEffect, useState, useMemo } from 'react';
import axios from 'axios';
import dayjs from 'dayjs';
import {  
  Search, 
  Filter, 
  Wallet, 
  Calendar, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  Copy, 
  Banknote, 
  Heart, 
  Sprout, 
  Building, 
  Gift,
  ChevronLeft,
  ChevronRight,
  Download
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import DashboardLoader from '@/lib/loader'; // Adjust path as needed

// --- Types ---
interface Member {
  id: number;
  full_name: string;
  e_kanisa_number: string;
  congregation: string;
}

interface PaymentItem {
  id: number;
  amount: number;
  status: string;
  created_at: string;
  mpesa_receipt_number?: string;
  account_reference?: string;
  member: Member | null;
}

interface Paginated<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

// --- Helpers ---

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('en-KE', {
    style: 'currency',
    currency: 'KES',
    minimumFractionDigits: 0,
  }).format(amount);
};

const getContributionType = (ref?: string) => {
  // Using a stricter Blue/Slate palette for the theme
  if (!ref) return { label: 'General Giving', icon: Wallet, color: 'text-slate-600 bg-slate-100' };
  
  if (ref.endsWith('T')) return { label: 'Tithe', icon: Banknote, color: 'text-blue-700 bg-blue-50' };
  if (ref.endsWith('O')) return { label: 'Offering', icon: Gift, color: 'text-indigo-700 bg-indigo-50' };
  if (ref.endsWith('D')) return { label: 'Development', icon: Building, color: 'text-slate-700 bg-slate-100' };
  if (ref.endsWith('TG')) return { label: 'Thanksgiving', icon: Heart, color: 'text-blue-900 bg-blue-100' };
  if (ref.endsWith('FF')) return { label: 'First Fruit', icon: Sprout, color: 'text-sky-700 bg-sky-50' };
  
  return { label: 'General', icon: Wallet, color: 'text-slate-600 bg-slate-100' };
};

const getStatusBadge = (status: string) => {
  switch (status) {
    case 'confirmed':
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-green-50 text-green-700 border border-green-200">
          <CheckCircle2 className="w-3 h-3" /> Successful
        </span>
      );
    case 'pending':
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-700 border border-amber-200">
          <Clock className="w-3 h-3" /> Pending
        </span>
      );
    case 'failed':
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-red-50 text-red-700 border border-red-200">
          <XCircle className="w-3 h-3" /> Failed
        </span>
      );
    default:
      return <span className="text-slate-500 capitalize">{status}</span>;
  }
};

// --- Sub-Component: Transaction Row ---

const TransactionRow = ({ payment, index }: { payment: PaymentItem; index: number }) => {
  const typeInfo = getContributionType(payment.account_reference);
  const memberName = payment.member?.full_name || 'Anonymous / Guest';
  const initials = memberName.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();

  return (
    <motion.tr 
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05 }}
      className="group border-b border-slate-100 hover:bg-slate-50/80 transition-colors"
    >
      {/* 1. Date Column */}
      <td className="px-6 py-4 whitespace-nowrap">
        <div className="flex items-center gap-3 text-slate-600">
           <div className="p-2 bg-slate-100 rounded-lg text-slate-400 group-hover:text-blue-600 group-hover:bg-blue-50 transition-colors">
             <Calendar className="w-4 h-4" />
           </div>
           <div className="flex flex-col">
             <span className="text-sm font-bold text-slate-700">{dayjs(payment.created_at).format('DD MMM YYYY')}</span>
             <span className="text-xs text-slate-400 font-medium">{dayjs(payment.created_at).format('h:mm A')}</span>
           </div>
        </div>
      </td>

      {/* 2. Member Details */}
      <td className="px-6 py-4">
        <div className="flex items-center gap-3">
          <div className={`w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold ${payment.member ? 'bg-blue-950 text-white' : 'bg-slate-200 text-slate-500'}`}>
            {initials}
          </div>
          <div>
            <div className="text-sm font-semibold text-slate-800">{memberName}</div>
            <div className="text-xs text-slate-500 font-mono">
              {payment.member?.e_kanisa_number || payment.account_reference?.split('-')[0] || 'N/A'}
            </div>
          </div>
        </div>
      </td>

      {/* 3. Account Type(s) */}
      <td className="px-6 py-4">
        <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-bold ${typeInfo.color}`}>
          <typeInfo.icon className="w-3.5 h-3.5" />
          {typeInfo.label}
        </div>
      </td>

      {/* 4. Amount */}
      <td className="px-6 py-4 text-right">
        <div className="text-sm font-bold text-slate-900 font-mono tracking-tight">
          {formatCurrency(payment.amount)}
        </div>
      </td>

      {/* 5. Status */}
      <td className="px-6 py-4 text-center">
        {getStatusBadge(payment.status)}
      </td>

      {/* 6. M-Pesa Receipt Ref */}
      <td className="px-6 py-4 text-right">
        <div className="inline-flex items-center gap-2 px-3 py-1 border border-dashed border-slate-300 rounded bg-slate-50 font-mono text-xs text-slate-600 group-hover:border-blue-300 group-hover:text-blue-700 transition-colors cursor-pointer select-all" title="Copy Receipt">
          {payment.mpesa_receipt_number || 'NO-REF'}
          <Copy className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" />
        </div>
      </td>
    </motion.tr>
  );
};

// --- Main Component ---

const ContributionsPage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [perPage, setPerPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [payments, setPayments] = useState<PaymentItem[]>([]);
  const [total, setTotal] = useState(0);
  const [selectedCongregation, setSelectedCongregation] = useState("");
  const [congregations, setCongregations] = useState<string[]>([]);
  const [isFirstLoad, setIsFirstLoad] = useState(true);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("token") : null),
    []
  );

  const fetchData = async () => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      // Fetch Payments
      const params = new URLSearchParams({ q: query, page: page.toString(), per_page: perPage.toString() });
      if (selectedCongregation) params.append('congregation', selectedCongregation);
      
      const payRes = await axios.get<Paginated<PaymentItem>>(`${API_URL}/admin/contributions?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setPayments(payRes.data.data);
      setTotal(payRes.data.total);

      // Fetch Meta only once if empty
      if (congregations.length === 0) {
        const metaRes = await axios.get<string[]>(`${API_URL}/admin/contributions-meta/congregations`, {
           headers: { Authorization: `Bearer ${token}` },
        });
        setCongregations(metaRes.data);
      }
    } catch (e: any) {
      setError(e?.response?.data?.message || "Failed to load financial data.");
    } finally {
      setLoading(false);
      if(isFirstLoad) setIsFirstLoad(false);
    }
  };

  useEffect(() => {
    const handler = setTimeout(() => { setPage(1); fetchData(); }, 400);
    return () => clearTimeout(handler);
  }, [query, selectedCongregation]);

  useEffect(() => { fetchData(); }, [page, perPage]);

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  // --- LOADING STATE ---
  if (isFirstLoad && loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50">
        <DashboardLoader 
          title="Loading Financial Data" 
          subtitle="Retrieving transactions and records..." 
        />
      </div>
    );
  }

  return (
    <div className="p-6 md:p-10 min-h-screen bg-slate-50/50 font-sans text-slate-900">
      
      {/* --- Header --- */}
      <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 mb-8">
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
          <div className="flex items-center gap-3 mb-1">
            <div className="p-2.5 bg-blue-950 text-white rounded-xl shadow-sm">
              <Wallet className="w-6 h-6" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">Financial Contributions</h1>
          </div>
          <p className="text-slate-500 text-sm ml-1">Monitor real-time giving, tithes, and offerings</p>
        </motion.div>

        <div className="flex gap-3">
            <button className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 text-slate-600 text-sm font-medium rounded-xl hover:bg-slate-50 hover:text-blue-900 hover:border-blue-200 transition-all shadow-sm">
               <Download className="w-4 h-4" />
               Export Report
            </button>
        </div>
      </div>

      {/* --- Toolbar --- */}
      <div className="bg-white p-2 rounded-2xl border border-slate-200 shadow-sm mb-6 flex flex-col md:flex-row items-center gap-2">
        {/* Search */}
        <div className="relative flex-1 w-full">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by member, receipt, or reference..."
            className="w-full pl-10 pr-4 py-2.5 bg-transparent rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:bg-slate-50 transition-colors text-slate-700"
          />
        </div>

        <div className="h-8 w-[1px] bg-slate-200 hidden md:block" />

        {/* Filter */}
        <div className="relative w-full md:w-64">
          <Filter className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
          <select
            value={selectedCongregation}
            onChange={(e) => setSelectedCongregation(e.target.value)}
            className="w-full pl-10 pr-8 py-2.5 bg-transparent rounded-xl text-sm text-slate-600 focus:outline-none focus:bg-slate-50 appearance-none cursor-pointer"
          >
            <option value="">All Congregations</option>
            {congregations.map((c) => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>

      {/* --- Error State --- */}
      {error && (
         <div className="mb-6 p-4 rounded-xl bg-red-50 border border-red-100 text-red-600 text-sm font-medium">
           {error}
         </div>
      )}

      {/* --- Data Table --- */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-slate-50/80 border-b border-slate-200">
              <tr>
                {['Date', 'Member Details', 'Account Type(s)', 'Amount', 'Status', 'M-Pesa Receipt Ref'].map((h, i) => (
                  <th key={i} className={`px-6 py-4 text-xs font-bold text-slate-400 uppercase tracking-wider ${h === 'Amount' || h === 'M-PesaReceipt Ref' ? 'text-right' : ''} ${h === 'Status' ? 'text-center' : ''}`}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="bg-white">
              {loading && !isFirstLoad ? (
                 // Skeleton Rows
                 [...Array(5)].map((_, i) => (
                    <tr key={i} className="border-b border-slate-50">
                       <td colSpan={6} className="px-6 py-4">
                         <div className="flex items-center gap-4">
                           <div className="w-10 h-10 bg-slate-100 rounded-full animate-pulse"></div>
                           <div className="space-y-2 flex-1">
                             <div className="h-4 bg-slate-100 rounded w-1/3 animate-pulse"></div>
                             <div className="h-3 bg-slate-100 rounded w-1/4 animate-pulse"></div>
                           </div>
                         </div>
                       </td>
                    </tr>
                 ))
              ) : payments.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-16 text-center">
                    <div className="mx-auto w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mb-4">
                       <Search className="w-8 h-8 text-slate-300" />
                    </div>
                    <h3 className="text-slate-900 font-medium">No contributions found</h3>
                    <p className="text-slate-500 text-sm">Try adjusting your filters</p>
                  </td>
                </tr>
              ) : (
                <AnimatePresence>
                   {payments.map((payment, index) => (
                      <TransactionRow key={payment.id} payment={payment} index={index} />
                   ))}
                </AnimatePresence>
              )}
            </tbody>
          </table>
        </div>

        {/* --- Footer --- */}
        <div className="px-6 py-4 border-t border-slate-100 flex flex-col sm:flex-row justify-between items-center gap-4 bg-slate-50/30">
           <div className="text-xs text-slate-500 font-medium">
              Showing <span className="text-slate-900 font-bold">{payments.length}</span> of <span className="text-slate-900 font-bold">{total}</span> transactions
           </div>
           
           <div className="flex items-center gap-2">
              <select
                value={perPage}
                onChange={(e) => setPerPage(Number(e.target.value))}
                className="mr-2 bg-transparent text-xs font-medium text-slate-500 focus:outline-none cursor-pointer"
              >
                <option value={10}>10 / page</option>
                <option value={20}>20 / page</option>
                <option value={50}>50 / page</option>
              </select>

              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page <= 1 || loading}
                className="p-2 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 hover:border-blue-200 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm"
              >
                 <ChevronLeft className="w-4 h-4 text-slate-600" />
              </button>
              <span className="px-4 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-bold text-slate-700 shadow-sm">
                 {page}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages || loading}
                className="p-2 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 hover:border-blue-200 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm"
              >
                 <ChevronRight className="w-4 h-4 text-slate-600" />
              </button>
           </div>
        </div>
      </div>
    </div>
  );
};

export default ContributionsPage;