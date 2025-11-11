import { useState, useEffect } from 'react';
import { useOutletContext, Link } from 'react-router-dom';
import axios from 'axios';
import {
  Users,
  Building, // Replaced DollarSign & BarChart2 for new stat card
  UserPlus,
  Loader2,
  AlertTriangle,
  LucideUserCircle2,
  FileText,
  MapPin,
  Building2,
  Church,
} from 'lucide-react';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';

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
  icon: React.ElementType;
  path: string;
}

interface MemberDto {
  id: number;
  full_name: string;
  e_kanisa_number?: string;
  telephone?: string;
  email?: string;
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

// --- HELPER FUNCTIONS ---
const getGreeting = () => {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 12) return { text: 'Good Morning'};
  if (hour >= 12 && hour < 15) return { text: 'Good Afternoon'};
  return { text: 'Good Evening'};
};

const greeting = getGreeting();
const COLORS = ['#6366F1', '#EC4899', '#F59E0B', '#10B981', '#3B82F6', '#EF4444', '#8B5CF6', '#F43F5E'];

const Dashboard = () => {
  const { user } = useOutletContext<OutletContextType>();
  const [stats, setStats] = useState<StatCardData[] | null>(null);
  const [members, setMembers] = useState<MemberDto[]>([]);
  const [membersTotal, setMembersTotal] = useState<number>(0);
  const [regions, setRegions] = useState<Region[]>([]);
  const [presbyteries, setPresbyteries] = useState<Presbytery[]>([]);
  const [parishes, setParishes] = useState<Parish[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const API_URL = import.meta.env.VITE_API_URL;

  const quickActions: QuickActionData[] = [
    { text: 'Register New Member', icon: UserPlus, path: '/dashboard/members' },
    { text: 'View All Members', icon: Users, path: '/dashboard/members' },
    { text: 'Manage Regions', icon: MapPin, path: '/dashboard/regions' },
    { text: 'Manage Presbyteries', icon: Building2, path: '/dashboard/presbyteries' },
    { text: 'Manage Parishes', icon: Church, path: '/dashboard/parishes' },
    { text: 'Manage Groups', icon: Building, path: '/dashboard/groups' },
    { text: 'View Contributions', icon: FileText, path: '/dashboard/contributions' },
  ];

  useEffect(() => {
    const fetchDashboardData = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        setError("Authentication error. Please log in again.");
        setLoading(false);
        return;
      }

      try {
        const headers = { Authorization: `Bearer ${token}` };
        
        // Fetch all data in parallel
        const [membersResponse, regionsResponse, presbyteriesResponse, parishesResponse] = await Promise.all([
          axios.get<PaginatedResponse<MemberDto>>(
            `${API_URL}/admin/members?per_page=1000`,
            { headers }
          ),
          axios.get<PaginatedResponse<Region>>(
            `${API_URL}/admin/regions?per_page=1000`,
            { headers }
          ),
          axios.get<PaginatedResponse<Presbytery>>(
            `${API_URL}/admin/presbyteries?per_page=1000`,
            { headers }
          ),
          axios.get<PaginatedResponse<Parish>>(
            `${API_URL}/admin/parishes?per_page=1000`,
            { headers }
          ),
        ]);

        // Process Members
        const fetchedMembers = membersResponse.data.data;
        const totalMembers = membersResponse.data.total;
        const uniqueCongregations = new Set(fetchedMembers.map(m => m.congregation)).size;

        // Process Regions
        const fetchedRegions = regionsResponse.data.data || [];
        const totalRegions = regionsResponse.data.total || 0;

        // Process Presbyteries
        const fetchedPresbyteries = presbyteriesResponse.data.data || [];
        const totalPresbyteries = presbyteriesResponse.data.total || 0;

        // Process Parishes
        const fetchedParishes = parishesResponse.data.data || [];
        const totalParishes = parishesResponse.data.total || 0;

        // Create Stat Cards
        const statsData: StatCardData[] = [
          {
            title: 'Total Members Registered',
            value: totalMembers.toString(),
            change: `In ${uniqueCongregations} congregations`,
            icon: Users,
          },
          {
            title: 'Total Regions',
            value: totalRegions.toString(),
            change: `${totalPresbyteries} presbyteries`,
            icon: MapPin,
          },
          {
            title: 'Total Presbyteries',
            value: totalPresbyteries.toString(),
            change: `${totalParishes} parishes`,
            icon: Building2,
          },
          {
            title: 'Total Parishes',
            value: totalParishes.toString(),
            change: 'Across all regions',
            icon: Church,
          },
        ];

        setMembers(fetchedMembers);
        setMembersTotal(totalMembers);
        setRegions(fetchedRegions);
        setPresbyteries(fetchedPresbyteries);
        setParishes(fetchedParishes);
        setStats(statsData);

      } catch (err) {
        console.error("Error loading dashboard:", err);
        setError("Could not load dashboard data. Please try again later.");
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, [API_URL]);

  // Chart Data: Members by Congregation
  const congregationData = Object.entries(
    members.reduce((acc, curr) => {
      const congregation = curr.congregation || 'Unknown';
      acc[congregation] = (acc[congregation] || 0) + 1;
      return acc;
    }, {} as Record<string, number>)
  ).map(([name, value]) => ({ name, value }));

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-blue-100 to-indigo-200 p-4">
        <Loader2 className="w-24 h-24 text-green-600 animate-spin" />
        <p className="mt-4 text-lg text-slate-600 font-semibold">Loading your dashboard...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-red-100 to-pink-200 p-4 text-center">
        <AlertTriangle className="w-12 h-12 text-red-600" />
        <p className="mt-4 text-xl font-bold text-red-700">Oops!</p>
        <p className="mt-2 text-slate-700">{error}</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 dark:from-slate-900 dark:via-slate-800 dark:to-slate-900">
      <div className="max-w-7xl mx-auto p-6 space-y-8">
        {/* Greeting Section */}
        <div className="relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-600/10 via-purple-600/10 to-pink-600/10 rounded-3xl"></div>
          <div className="relative bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm p-8 rounded-3xl border border-white/20 dark:border-slate-700/50 shadow-xl">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-4xl font-bold bg-blue-800 dark:bg-slate-200 bg-clip-text text-transparent">
                  {greeting.text}, <span className="text-blue-600 dark:text-blue-400">{user.name}</span>
                </h1>
                <p className="mt-3 text-lg text-slate-600 dark:text-slate-300 font-medium">
                  Welcome back! Here's your ministry overview at a glance.
                </p>
              </div>
              
            </div>
          </div>
        </div>

        {/* Stat Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {stats?.map((stat, index) => (
            <div key={index} className="group relative overflow-hidden bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm p-6 rounded-2xl border border-slate-200/50 dark:border-slate-700/50 shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="absolute inset-0 bg-gradient-to-br from-blue-500/5 via-purple-500/5 to-pink-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
              <div className="relative z-10">
                <div className="flex items-center justify-between mb-4">
                  <div className="p-3 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 text-white shadow-lg"><stat.icon className="w-6 h-6" /></div>
                  <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide text-right">{stat.title}</p>
                </div>
                <div className="space-y-2">
                  <p className="text-3xl font-bold text-slate-900 dark:text-white">{stat.value}</p>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-green-500"></div>
                    <p className="text-sm font-medium text-green-600 dark:text-green-400">{stat.change}</p>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Main Content: Quick Actions & Members Overview */}
        <div className="bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm p-6 rounded-2xl border border-slate-200/50 dark:border-slate-700/50 shadow-lg">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Quick Actions */}
                <div>
                    <div className="flex items-center justify-between mb-6">
                        <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Quick Actions</h2>
                        <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                    </div>
                    <div className="space-y-3">
                    {quickActions.map((action, index) => (
                        <Link key={index} to={action.path} className="group flex items-center gap-4 p-4 bg-gradient-to-r from-slate-50 to-blue-50 dark:from-slate-700/50 dark:to-blue-900/20 rounded-xl hover:from-blue-50 hover:to-indigo-50 dark:hover:from-blue-900/30 dark:hover:to-indigo-900/30 transition-all duration-200 border border-slate-200/50 dark:border-slate-600/50 hover:border-blue-300/50 dark:hover:border-blue-600/50 hover:shadow-md">
                        <div className="flex items-center justify-center w-12 h-12 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl shadow-md group-hover:shadow-lg transition-shadow duration-200"><action.icon className="w-6 h-6 text-white" /></div>
                        <div className="flex-1"><span className="font-semibold text-slate-900 dark:text-white group-hover:text-blue-700 dark:group-hover:text-blue-300 transition-colors duration-200">{action.text}</span><p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Click to proceed</p></div>
                        </Link>
                    ))}
                    </div>
                </div>

                {/* New Members List */}
                <div>
                    <div className="flex items-center justify-between mb-6">
                        <h3 className="text-2xl font-bold text-slate-900 dark:text-white">New Members</h3>
                        <Link to="/members" className="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 text-sm font-medium rounded-full hover:bg-green-200 dark:hover:bg-green-800/50 transition-colors">{membersTotal} total</Link>
                    </div>
                    <div className="space-y-3 max-h-[24.5rem] overflow-y-auto scrollbar-thin scrollbar-thumb-slate-300 dark:scrollbar-thumb-slate-600 scrollbar-track-transparent pr-2">
                    {members.slice(0, 15).map((m) => (
                        <div key={m.id} className="flex items-center gap-3 p-3 bg-slate-50 dark:bg-slate-700/50 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors duration-200">
                        <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white text-sm font-semibold">{m.full_name.charAt(0).toUpperCase()}</div>
                        <div className="flex-1 min-w-0">
                            <p className="font-medium text-slate-900 dark:text-white truncate">{m.full_name}</p>
                            <div className="flex items-center gap-4 text-xs text-slate-500 dark:text-slate-400"><span>{m.congregation || 'No Congregation'}</span></div>
                        </div>
                        </div>
                    ))}
                    {members.length === 0 && (
                        <div className="text-center py-8">
                        <div className="w-12 h-12 bg-slate-200 dark:bg-slate-700 rounded-full flex items-center justify-center mx-auto mb-3"><LucideUserCircle2 className="w-6 h-6 text-slate-400 dark:text-slate-500" /></div>
                        <p className="text-slate-500 dark:text-slate-400 text-sm">No members found</p>
                        </div>
                    )}
                    </div>
                </div>
            </div>
        </div>

        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Member Distribution by Congregation */}
          <div className="bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm p-8 rounded-2xl border border-slate-200/50 dark:border-slate-700/50 shadow-lg">
            <div className="flex items-center justify-between mb-8">
              <div>
                <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Members by Congregation</h2>
                <p className="text-slate-600 dark:text-slate-400 mt-2">Distribution of members across different congregations</p>
              </div>
              <div className="px-4 py-2 bg-blue-500 text-white text-sm font-medium rounded-full">Total {membersTotal} Members</div>
            </div>
            <ResponsiveContainer width="100%" height={400}>
              <PieChart>
                <Pie data={congregationData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={120} innerRadius={60} label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`} labelLine={false}>
                  {congregationData.map((_, index) => (<Cell key={index} fill={COLORS[index % COLORS.length]} />))}
                </Pie>
                <Tooltip formatter={(value, name) => [`${value} members`, name]}/>
                <Legend verticalAlign="bottom" height={36} wrapperStyle={{ fontSize: '14px' }} />
              </PieChart>
            </ResponsiveContainer>
          </div>

          {/* Regions Overview */}
          <div className="bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm p-8 rounded-2xl border border-slate-200/50 dark:border-slate-700/50 shadow-lg">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Regions Overview</h2>
                <p className="text-slate-600 dark:text-slate-400 mt-2">Church structure hierarchy</p>
              </div>
              <Link to="/dashboard/regions" className="px-4 py-2 bg-blue-500 text-white text-sm font-medium rounded-full hover:from-green-600 hover:to-emerald-700 transition-colors">
                Manage
              </Link>
            </div>
            <div className="space-y-4 max-h-[400px] overflow-y-auto scrollbar-thin scrollbar-thumb-slate-300 dark:scrollbar-thumb-slate-600 scrollbar-track-transparent pr-2">
              {regions.length === 0 ? (
                <div className="text-center py-8">
                  <MapPin className="w-12 h-12 text-slate-400 dark:text-slate-500 mx-auto mb-3" />
                  <p className="text-slate-500 dark:text-slate-400 text-sm">No regions found</p>
                </div>
              ) : (
                regions.map((region) => {
                  const regionPresbyteries = presbyteries.filter(p => p.region_id === region.id);
                  const regionParishes = parishes.filter(p => 
                    regionPresbyteries.some(pres => pres.id === p.presbytery_id)
                  );
                  
                  return (
                    <div key={region.id} className="p-4 bg-gradient-to-r from-slate-50 to-blue-50 dark:from-slate-700/50 dark:to-blue-900/20 rounded-xl border border-slate-200/50 dark:border-slate-600/50 hover:shadow-md transition-shadow">
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <MapPin className="w-5 h-5 text-blue-600" />
                          <h3 className="font-bold text-slate-900 dark:text-white">{region.name}</h3>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 gap-3 mt-3">
                        <div className="flex items-center gap-2 text-sm">
                          <Building2 className="w-4 h-4 text-indigo-600" />
                          <span className="text-slate-600 dark:text-slate-400">
                            <strong className="text-slate-900 dark:text-white">{regionPresbyteries.length}</strong> Presbytery{regionPresbyteries.length !== 1 ? 'ies' : ''}
                          </span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                          <Church className="w-4 h-4 text-green-600" />
                          <span className="text-slate-600 dark:text-slate-400">
                            <strong className="text-slate-900 dark:text-white">{regionParishes.length}</strong> Parishes
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;