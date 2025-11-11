import { useEffect, useState, useMemo } from 'react';
import axios from 'axios';
import dayjs from 'dayjs';
import { Loader2 } from 'lucide-react';

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

// --- COMPONENT DEFINITIONS ---

function PaymentRow({ payment }: { payment: PaymentItem }) {
  return (
    <tr className="hover:bg-slate-50">
      <td className="px-4 py-3 text-sm text-slate-900">{dayjs(payment.created_at).format('DD MMM YYYY')}</td>
      <td className="px-4 py-3 text-sm text-slate-900">
        <div>
          <div className="font-medium">{payment.member?.full_name || 'Unknown Member'}</div>
          <div className="text-slate-500">({payment.member?.e_kanisa_number || payment.account_reference || 'N/A'})</div>
        </div>
      </td>
      <td className="px-4 py-3 text-sm text-slate-900 capitalize">
        {payment.account_reference ? 
          (payment.account_reference.endsWith('T') ? 'Tithe' :
           payment.account_reference.endsWith('O') ? 'Offering' :
           payment.account_reference.endsWith('D') ? 'Development' :
           payment.account_reference.endsWith('TG') ? 'Thanksgiving' :
           payment.account_reference.endsWith('FF') ? 'First Fruit' :
           'General') : 'General'}
      </td>
      <td className="px-4 py-3 text-sm font-medium text-slate-900">KES {payment.amount.toLocaleString()}</td>
      <td className="px-4 py-3 text-sm">
        <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
          payment.status === 'confirmed' ? 'bg-green-100 text-green-800' :
          payment.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
          payment.status === 'failed' ? 'bg-red-100 text-red-800' :
          'bg-gray-100 text-gray-800'
        }`}>
          {payment.status}
        </span>
      </td>
      <td className="px-4 py-3 text-sm text-slate-500">{payment.mpesa_receipt_number || '-'}</td>
    </tr>
  );
}

// --- MAIN PAGE COMPONENT ---

export default function ContributionsPage() {
  const API_URL = import.meta.env.VITE_API_URL;
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [perPage] = useState(10);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [payments, setPayments] = useState<PaymentItem[]>([]);
  const [total, setTotal] = useState(0);
  const [selectedCongregation, setSelectedCongregation] = useState("");
  const [congregations, setCongregations] = useState<string[]>([]);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("token") : null),
    []
  );

  const fetchContributions = async () => {
    if (!token) {
      setError("Authentication token not found. Please log in.");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        q: query,
        page: page.toString(),
        per_page: perPage.toString(),
      });
      
      if (selectedCongregation) {
        params.append('congregation', selectedCongregation);
      }
      
      const url = `${API_URL}/admin/contributions?${params.toString()}`;
      const res = await axios.get<Paginated<PaymentItem>>(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setPayments(res.data.data);
      setTotal(res.data.total);
    } catch (e: any) {
      setError(
        e?.response?.data?.message || e?.message || "Failed to load contributions"
      );
    } finally {
      setLoading(false);
    }
  };

  const fetchCongregations = async () => {
    try {
      const res = await axios.get<string[]>(`${API_URL}/admin/contributions-meta/congregations`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCongregations(res.data);
    } catch (e: any) {
      console.error("Failed to load congregations:", e);
    }
  };

  useEffect(() => {
    // Debounced search and fetch
    const handler = setTimeout(() => {
      setPage(1); // Reset to first page on new search
      fetchContributions();
    }, 300);

    return () => clearTimeout(handler);
  }, [query, selectedCongregation]);

  useEffect(() => {
    // Fetch when page or perPage changes
    fetchContributions();
  }, [page, perPage]);

  useEffect(() => {
    fetchCongregations();
  }, []);

  const totalPages = Math.max(1, Math.ceil(total / perPage));

  // Initial full-page loader
  if (loading && payments.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-200px)] bg-slate-50 p-4">
        <Loader2 className="w-16 h-16 text-green-600 animate-spin" />
        <p className="mt-4 text-lg text-slate-600 font-semibold">Loading contributions...</p>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 bg-slate-50 min-h-full">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-3xl font-bold text-slate-800">Member Contributions</h1>
        <div className="flex items-center gap-4">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search payments..."
            className="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
          <select
            value={selectedCongregation}
            onChange={(e) => setSelectedCongregation(e.target.value)}
            className="px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          >
            <option value="">All Congregations</option>
            {congregations.map((congregation) => (
              <option key={congregation} value={congregation}>
                {congregation}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}

      {/* Payments Table */}
      <div className="bg-white rounded-xl border border-slate-200/60 shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Date</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Member</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Type</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Amount</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">M-Pesa Receipt</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-slate-500">
                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />
                    Loading payments...
                  </td>
                </tr>
              ) : payments.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-slate-500">No payments found.</td>
                </tr>
              ) : (
                payments.map((payment) => (
                  <PaymentRow key={payment.id} payment={payment} />
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {payments.length > 0 && (
          <div className="flex items-center justify-between p-4 border-t">
            <div className="text-sm text-slate-600">
              Showing {((page - 1) * perPage) + 1} to {Math.min(page * perPage, total)} of {total} payments
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page <= 1}
                className="px-3 py-1 text-sm border rounded-md hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              <span className="px-3 py-1 text-sm text-slate-600">
                Page {page} of {totalPages}
              </span>
              <button
                onClick={() => setPage(Math.min(totalPages, page + 1))}
                disabled={page >= totalPages}
                className="px-3 py-1 text-sm border rounded-md hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}