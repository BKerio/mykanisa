import { useEffect, useState } from 'react';
import axios from 'axios';
import { Settings, Save, Eye, EyeOff, MessageSquare, RefreshCw } from 'lucide-react';
import { motion } from 'framer-motion';
import Swal from 'sweetalert2';
import DashboardLoader from '@/lib/loader';

interface SystemConfig {
  id: number;
  key: string;
  value: string;
  type: string;
  category: string;
  description: string | null;
  is_encrypted: boolean;
  is_masked?: boolean;
  created_at: string;
  updated_at: string;
}

const SystemConfigPage = () => {
  const [configs, setConfigs] = useState<SystemConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [visiblePasswords, setVisiblePasswords] = useState<Record<string, boolean>>({});
  const [editedConfigs, setEditedConfigs] = useState<Record<string, string>>({});

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

  useEffect(() => {
    loadConfigs();
  }, []);

  const loadConfigs = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/admin/system-config/category/sms`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.data.status === 200) {
        setConfigs(response.data.configs);
        // Initialize edited configs with current values
        const initial: Record<string, string> = {};
        response.data.configs.forEach((config: SystemConfig) => {
          if (!config.is_masked) {
            initial[config.key] = config.value;
          }
        });
        setEditedConfigs(initial);
      }
    } catch (error: any) {
      console.error('Error loading configs:', error);
      Swal.fire({
        icon: 'error',
        title: 'Error',
        text: error.response?.data?.message || 'Failed to load system configuration',
        confirmButtonColor: '#2563eb',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleValueChange = (key: string, value: string) => {
    setEditedConfigs((prev) => ({
      ...prev,
      [key]: value,
    }));
  };

  const togglePasswordVisibility = (key: string) => {
    setVisiblePasswords((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const token = localStorage.getItem('token');

      // Prepare configs for bulk update - only include changed values
      const configsToUpdate = Object.entries(editedConfigs)
        .filter(([key, value]) => {
          const originalConfig = configs.find(c => c.key === key);
          if (!originalConfig) return false;
          // For encrypted/masked values, any non-empty value is considered a change
          if (originalConfig.is_masked) {
            return value && value.trim() !== '';
          }
          // For other values, check if it's different from original
          return value !== originalConfig.value;
        })
        .map(([key, value]) => ({
          key,
          value,
        }));

      const response = await axios.post(
        `${API_URL}/admin/system-config/bulk-update`,
        { configs: configsToUpdate },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.data.status === 200) {
        Swal.fire({
          icon: 'success',
          title: 'Success',
          text: 'SMS configuration updated successfully',
          confirmButtonColor: '#2563eb',
          timer: 2000,
        });
        await loadConfigs();
        setVisiblePasswords({});
      }
    } catch (error: any) {
      console.error('Error saving configs:', error);
      Swal.fire({
        icon: 'error',
        title: 'Error',
        text: error.response?.data?.message || 'Failed to save configuration',
        confirmButtonColor: '#2563eb',
      });
    } finally {
      setSaving(false);
    }
  };

  const handleTestSms = async () => {
    // This would require a test endpoint - for now just show info
    Swal.fire({
      icon: 'info',
      title: 'Test SMS',
      text: 'Test SMS functionality will be available after saving the configuration',
      confirmButtonColor: '#2563eb',
    });
  };

  const hasChanges = () => {
    return Object.keys(editedConfigs).length > 0;
  };

  if (loading) {
    return <DashboardLoader />;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 p-6">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-blue-100 dark:bg-blue-900 rounded-xl">
                <Settings className="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  System Configuration
                </h1>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Manage SMS service settings
                </p>
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={loadConfigs}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors flex items-center gap-2"
              >
                <RefreshCw className="w-4 h-4" />
                Refresh
              </button>
              <button
                onClick={handleSave}
                disabled={!hasChanges() || saving}
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
              >
                {saving ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    Save Changes
                  </>
                )}
              </button>
            </div>
          </div>
        </motion.div>

        {/* SMS Configuration Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden"
        >
          <div className="p-6 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <MessageSquare className="w-5 h-5 text-blue-600 dark:text-blue-400" />
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                SMS Service Configuration
              </h2>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              Configure your SMS provider settings. Changes take effect immediately after saving.
            </p>
          </div>

          <div className="p-6 space-y-6">
            {configs.map((config, index) => (
              <motion.div
                key={config.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05 }}
                className="space-y-2"
              >
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                  {config.description || config.key.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase())}
                  {config.is_encrypted && (
                    <span className="ml-2 text-xs text-amber-600 dark:text-amber-400">
                      (Encrypted)
                    </span>
                  )}
                </label>

                <div className="relative">
                  {config.is_encrypted ? (
                    <div className="flex gap-2">
                      <input
                        type={visiblePasswords[config.key] ? 'text' : 'password'}
                        value={editedConfigs[config.key] !== undefined ? editedConfigs[config.key] : ''}
                        onChange={(e) => handleValueChange(config.key, e.target.value)}
                        placeholder={config.is_masked ? 'Enter new API key' : 'Enter value'}
                        className="flex-1 px-4 py-2.5 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                      <button
                        type="button"
                        onClick={() => togglePasswordVisibility(config.key)}
                        className="px-4 py-2.5 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                      >
                        {visiblePasswords[config.key] ? (
                          <EyeOff className="w-5 h-5" />
                        ) : (
                          <Eye className="w-5 h-5" />
                        )}
                      </button>
                    </div>
                  ) : config.type === 'boolean' ? (
                    <div className="flex items-center gap-4">
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          checked={editedConfigs[config.key] === 'true' || (!editedConfigs[config.key] && config.value === 'true')}
                          onChange={(e) => handleValueChange(config.key, e.target.checked ? 'true' : 'false')}
                          className="sr-only peer"
                        />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
                        <span className="ml-3 text-sm font-medium text-gray-700 dark:text-gray-300">
                          {editedConfigs[config.key] === 'true' || (!editedConfigs[config.key] && config.value === 'true') ? 'Enabled' : 'Disabled'}
                        </span>
                      </label>
                    </div>
                  ) : (
                    <input
                      type="text"
                      value={editedConfigs[config.key] !== undefined ? editedConfigs[config.key] : config.value}
                      onChange={(e) => handleValueChange(config.key, e.target.value)}
                      className="w-full px-4 py-2.5 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder={config.value}
                    />
                  )}
                </div>

                {config.key && (
                  <p className="text-xs text-gray-500 dark:text-gray-400 font-mono">
                    Key: {config.key}
                  </p>
                )}
              </motion.div>
            ))}
          </div>

          {/* Info Box */}
          <div className="p-6 bg-blue-50 dark:bg-blue-900/20 border-t border-gray-200 dark:border-gray-700">
            <div className="flex gap-3">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                  <MessageSquare className="w-4 h-4 text-blue-600 dark:text-blue-400" />
                </div>
              </div>
              <div className="flex-1">
                <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                  Configuration Tips
                </h3>
                <ul className="text-xs text-gray-600 dark:text-gray-400 space-y-1 list-disc list-inside">
                  <li>API Key and sensitive credentials are encrypted in the database</li>
                  <li>Changes take effect immediately after saving</li>
                  <li>Disable SMS service by toggling "SMS Enabled" to off</li>
                  <li>Ensure your API endpoint URL is correct for your provider</li>
                </ul>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default SystemConfigPage;

