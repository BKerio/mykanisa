import { useState, useEffect } from 'react';
import { useOutletContext, Link } from 'react-router-dom';
import axios from 'axios';
import {
  Users,
  Building, 
  UserPlus,
  AlertTriangle,
  FileText,
  MapPin,
  Building2,
  Church,
  ArrowUpRight,
  Calendar,
  ChevronRight
} from 'lucide-react';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { motion } from 'framer-motion';
import dayjs from 'dayjs';
import DashboardLoader from '@/lib/loader'; // Adjust path as needed

// --- TYPE DEFINITIONS ---
interface UserProfile {
  name: string;
  email: string;
}

interface OutletContextType {
  user: UserProfile;
}

interface StatCardData {
  title: string;
  value: string;
  change: string;
  icon: React.ElementType;
}

interface QuickActionData {
  text: string;
  desc: string;
  icon: React.ElementType;
  path: string;
}

interface MemberDto {
  id: number;
  full_name: string;
  e_kanisa_number?: string;
  congregation: string;
}

interface Region {
  id: number;
  name: string;
  presbyteries_count?: number;
}

interface Presbytery {
  id: number;
  name: string;
  region_id: number;
  parishes_count?: number;
}

interface Parish {
  id: number;
  name: string;
  presbytery_id: number;
}

interface PaginatedResponse<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

// --- CONSTANTS & HELPERS ---
const BLUE_PALETTE = [
  '#172554', // blue-950
  '#1e40af', // blue-800
  '#2563eb', // blue-600
  '#60a5fa', // blue-400
  '#93c5fd', // blue-300
  '#cbd5e1', // slate-300
];

const getGreeting = () => {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 12) return 'Good Morning';
  if (hour >= 12 && hour < 18) return 'Good Afternoon';
  return 'Good Evening';
};

// --- SUB-COMPONENTS ---

// 1. Stat Card
const StatCard = ({ stat, index }: { stat: StatCardData; index: number }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ delay: index * 0.1 }}
    className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md hover:border-blue-200 transition-all duration-300 group"
  >
    <div className="flex justify-between items-start">
      <div>
        <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">{stat.title}</p>
        <h3 className="text-3xl font-bold text-slate-900 group-hover:text-blue-900 transition-colors">{stat.value}</h3>
      </div>
      <div className="p-3 bg-slate-50 rounded-xl group-hover:bg-blue-50 group-hover:text-blue-600 text-slate-400 transition-colors">
        <stat.icon className="w-6 h-6" />
      </div>
    </div>
    <div className="mt-4 flex items-center gap-2 text-sm text-slate-500">
      <div className="w-1.5 h-1.5 rounded-full bg-blue-500" />
      {stat.change}
    </div>
  </motion.div>
);

// 2. Custom Tooltip for Chart
const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-slate-900 text-white text-xs p-3 rounded-lg shadow-xl border border-slate-700">
        <p className="font-bold mb-1">{payload[0].name}</p>
        <p className="text-blue-200">{payload[0].value} Members</p>
      </div>
    );
  }
  return null;
};

// --- MAIN COMPONENT ---

const Dashboard = () => {
  const { user } = useOutletContext<OutletContextType>();
  
  // State
  const [stats, setStats] = useState<StatCardData[] | null>(null);
  const [members, setMembers] = useState<MemberDto[]>([]);
  const [regions, setRegions] = useState<Region[]>([]);
  const [presbyteries, setPresbyteries] = useState<Presbytery[]>([]);
  const [parishes, setParishes] = useState<Parish[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const API_URL = import.meta.env.VITE_API_URL;

  const quickActions: QuickActionData[] = [
    { text: 'New Member', desc: 'Register profile', icon: UserPlus, path: '/dashboard/members' },
    { text: 'Directory', desc: 'View all', icon: Users, path: '/dashboard/members' },
    { text: 'Finance', desc: 'Contributions', icon: FileText, path: '/dashboard/contributions' },
    { text: 'Structure', desc: 'Manage Regions', icon: MapPin, path: '/dashboard/regions' },
  ];

  useEffect(() => {
    const fetchDashboardData = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        setError("Authentication error. Please log in.");
        setLoading(false);
        return;
      }

      try {
        const headers = { Authorization: `Bearer ${token}` };
        
        const [membersRes, regionsRes, presbyteriesRes, parishesRes] = await Promise.all([
          axios.get<PaginatedResponse<MemberDto>>(`${API_URL}/admin/members?per_page=1000`, { headers }),
          axios.get<PaginatedResponse<Region>>(`${API_URL}/admin/regions?per_page=1000`, { headers }),
          axios.get<PaginatedResponse<Presbytery>>(`${API_URL}/admin/presbyteries?per_page=1000`, { headers }),
          axios.get<PaginatedResponse<Parish>>(`${API_URL}/admin/parishes?per_page=1000`, { headers }),
        ]);

        const mData = membersRes.data.data;
        const totalM = membersRes.data.total;
        const uniqueCongregations = new Set(mData.map(m => m.congregation)).size;

        const rData = regionsRes.data.data || [];
        const pData = presbyteriesRes.data.data || [];
        const parishData = parishesRes.data.data || [];

        setStats([
          { title: 'Total Membership', value: totalM.toString(), change: `${uniqueCongregations} Active Congregations`, icon: Users },
          { title: 'Regions', value: rData.length.toString(), change: 'Geographical Areas', icon: MapPin },
          { title: 'Presbyteries', value: pData.length.toString(), change: 'Administrative Units', icon: Building2 },
          { title: 'Parishes', value: parishData.length.toString(), change: 'Local Assemblies', icon: Church },
        ]);

        setMembers(mData);
        setRegions(rData);
        setPresbyteries(pData);
        setParishes(parishData);

      } catch (err) {
        setError("Unable to sync dashboard data.");
      } finally {
        // Minimum loading time to see the animation
        setTimeout(() => setLoading(false), 800);
      }
    };

    fetchDashboardData();
  }, [API_URL]);

  // Process Chart Data
  const congregationData = Object.entries(
    members.reduce((acc, curr) => {
      const c = curr.congregation || 'Unknown';
      acc[c] = (acc[c] || 0) + 1;
      return acc;
    }, {} as Record<string, number>)
  )
  .map(([name, value]) => ({ name, value }))
  .sort((a, b) => b.value - a.value) // Sort by size
  .slice(0, 6); // Top 6 only

  // --- LOAD STATE ---
  if (loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50">
        <DashboardLoader 
          title="Syncing Dashboard" 
          subtitle="Gathering metrics, structure data, and membership records..." 
        />
      </div>
    );
  }

  // --- ERROR STATE ---
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[80vh] p-4">
        <div className="bg-red-50 p-6 rounded-2xl border border-red-100 text-center max-w-md">
          <AlertTriangle className="w-12 h-12 text-red-900 mx-auto mb-4" />
          <h3 className="text-lg font-bold text-red-900">Dashboard Error</h3>
          <p className="text-red-700 mt-2 text-sm">{error}</p>
        </div>
      </div>
    );
  }

  // --- MAIN UI ---
  return (
    <div className="min-h-screen bg-slate-50/50 p-6 md:p-8 font-sans text-slate-900">
      
      {/* 1. Header / Welcome */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
          <p className="text-slate-500 font-medium mb-1 flex items-center gap-2">
             <Calendar className="w-4 h-4" /> {dayjs().format('dddd, D MMMM YYYY')}
          </p>
          <h1 className="text-3xl font-bold text-slate-900">
            {getGreeting()}, <span className="text-blue-900">{user.name.split(' ')[0]}</span>
          </h1>
        </motion.div>
        
        <motion.div 
          initial={{ opacity: 0 }} 
          animate={{ opacity: 1 }} 
          className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-full shadow-sm text-sm font-medium text-slate-600"
        >
          <div className="w-3 h-3 bg-green-700 rounded-full animate-pulse"></div>
          System Operational
        </motion.div>
      </div>

      {/* 2. Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {stats?.map((stat, index) => (
          <StatCard key={index} stat={stat} index={index} />
        ))}
      </div>

      {/* 3. Main Bento Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* LEFT COLUMN (2/3 Width) */}
        <div className="lg:col-span-2 space-y-8">
          
          {/* A. Quick Actions */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {quickActions.map((action, idx) => (
              <Link key={idx} to={action.path}>
                <motion.div 
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm hover:border-blue-300 hover:shadow-md transition-all cursor-pointer flex flex-col items-center text-center gap-3"
                >
                  <div className="w-12 h-12 bg-slate-50 rounded-full flex items-center justify-center text-blue-900 group-hover:bg-blue-900 group-hover:text-white transition-colors">
                    <action.icon className="w-6 h-6" />
                  </div>
                  <div>
                    <h4 className="font-bold text-slate-800 text-sm">{action.text}</h4>
                    <p className="text-xs text-slate-500 mt-0.5">{action.desc}</p>
                  </div>
                </motion.div>
              </Link>
            ))}
          </div>

          {/* B. Analytics Chart */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm"
          >
            <div className="flex justify-between items-center mb-6">
              <div>
                 <h3 className="font-bold text-lg text-slate-900">Congregation Distribution</h3>
                 <p className="text-sm text-slate-500">Membership breakdown by branch</p>
              </div>
              <button className="p-2 hover:bg-slate-50 rounded-lg transition-colors">
                 <ArrowUpRight className="w-5 h-5 text-slate-400" />
              </button>
            </div>
            
            <div className="h-[300px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={congregationData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {congregationData.map((_, index) => (
                      <Cell key={`cell-${index}`} fill={BLUE_PALETTE[index % BLUE_PALETTE.length]} stroke="none" />
                    ))}
                  </Pie>
                  <Tooltip content={<CustomTooltip />} />
                  <Legend 
                    verticalAlign="bottom" 
                    height={36} 
                    iconType="circle"
                    formatter={(value) => <span className="text-slate-600 text-xs font-medium ml-1">{value}</span>}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </motion.div>
        </div>

        {/* RIGHT COLUMN (1/3 Width) */}
        <div className="space-y-8">
          
          {/* A. Recent Members List */}
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden"
          >
            <div className="p-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
              <h3 className="font-bold text-slate-900">Recent Members</h3>
              <Link to="/dashboard/members" className="text-xs font-bold text-blue-600 hover:text-blue-800 flex items-center">
                View All <ChevronRight className="w-3 h-3 ml-1" />
              </Link>
            </div>
            <div className="divide-y divide-slate-100 max-h-[350px] overflow-y-auto">
              {members.slice(0, 7).map((m) => (
                <div key={m.id} className="p-4 flex items-center gap-3 hover:bg-slate-50 transition-colors">
                   <div className="w-10 h-10 rounded-full bg-blue-950 text-white flex items-center justify-center text-xs font-bold">
                      {m.full_name.substring(0, 2).toUpperCase()}
                   </div>
                   <div className="flex-1 min-w-0">
                      <p className="text-sm font-bold text-slate-800 truncate">{m.full_name}</p>
                      <p className="text-xs text-slate-500 truncate">{m.congregation || 'Unassigned'}</p>
                   </div>
                   <div className="w-2 h-2 rounded-full bg-blue-400"></div>
                </div>
              ))}
            </div>
          </motion.div>

          {/* B. Hierarchy Summary */}
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4 }}
            className="bg-blue-950 rounded-2xl shadow-lg p-6 text-white relative overflow-hidden"
          >
             <div className="absolute top-0 right-0 opacity-10 transform translate-x-8 -translate-y-8">
                <Building size={150} />
             </div>
             
             <div className="relative z-10">
               <h3 className="font-bold text-lg mb-1">Structure Status</h3>
               <p className="text-blue-200 text-xs mb-6">Overview of administrative units</p>
               
               <div className="space-y-4">
                  <div className="flex justify-between items-center border-b border-blue-800 pb-2">
                     <span className="text-sm text-blue-100 flex items-center gap-2">
                        <MapPin className="w-4 h-4" /> Regions
                     </span>
                     <span className="font-bold">{regions.length}</span>
                  </div>
                  <div className="flex justify-between items-center border-b border-blue-800 pb-2">
                     <span className="text-sm text-blue-100 flex items-center gap-2">
                        <Building2 className="w-4 h-4" /> Presbyteries
                     </span>
                     <span className="font-bold">{presbyteries.length}</span>
                  </div>
                  <div className="flex justify-between items-center">
                     <span className="text-sm text-blue-100 flex items-center gap-2">
                        <Church className="w-4 h-4" /> Parishes
                     </span>
                     <span className="font-bold">{parishes.length}</span>
                  </div>
               </div>

               <Link to="/dashboard/regions" className="mt-6 w-full py-2 bg-white text-blue-950 text-sm font-bold rounded-lg flex items-center justify-center hover:bg-blue-50 transition-colors">
                  Manage Structure
               </Link>
             </div>
          </motion.div>

        </div>
      </div>
    </div>
  );
};

export default Dashboard;