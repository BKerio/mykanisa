// src/components/Login.tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import toast, { Toaster } from 'react-hot-toast';
import { Eye, EyeOff, Mail, Lock } from 'lucide-react';

import Admin_Avator from "@/assets/icon.png";

function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email || !password) {
      toast.error('Please enter email and password.');
      return;
    }

    try {
      const res = await axios.post(`${import.meta.env.VITE_API_URL}/admin/login`, {
        email,
        password
      });

      localStorage.setItem('token', res.data.token);

      toast.success('Login successful.');

      setTimeout(() => {
        navigate('/dashboard');
      }, 1200);
    } catch (err) {
      let errorMessage = 'Login failed. Please try again.';

      if (axios.isAxiosError(err)) {
        errorMessage = err.response?.data?.message || err.message || errorMessage;
      } else if (err instanceof Error) {
        errorMessage = err.message || errorMessage;
      }

      toast.error(errorMessage);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 px-4">

      {/* Toast at bottom with bigger text */}
      <Toaster
        position="bottom-center"
        toastOptions={{
          style: {
            fontSize: '1rem',
            padding: '14px 18px',
          }
        }}
      />

      <div className="relative bg-white shadow-lg rounded-xl w-full max-w-md p-8 border border-gray-200">
        
        {/* Admin Avatar */}
        <div className="flex flex-col items-center mb-6 mt-2">
          <div className="w-32 h-32 rounded-full overflow-hidden shadow-md border border-gray-300">
            <img
              src={Admin_Avator}
              alt="Admin Avatar"
              draggable={false}
              className="w-full h-full object-cover"
            />
          </div>

          <h2 className="text-2xl font-semibold text-gray-800 mt-4">
            Admin Login
          </h2>
          <p className="text-gray-500 text-sm mt-1">
            Secure access for administrators only
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          
          {/* Email Input */}
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="email"
              placeholder="admin@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full p-3 pl-10 border border-gray-300 rounded-md bg-white placeholder-gray-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
              required
            />
          </div>

          {/* Password Input */}
          <div className="relative">
            <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type={showPassword ? 'text' : 'password'}
              placeholder="*********"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full p-3 pl-10 pr-10 border border-gray-300 rounded-md bg-white placeholder-gray-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
              required
            />
            <button
              type="button"
              className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400"
              onClick={() => setShowPassword(!showPassword)}
              aria-label={showPassword ? 'Hide password' : 'Show password'}
            >
              {showPassword ? (
                <EyeOff className="w-5 h-5" />
              ) : (
                <Eye className="w-5 h-5" />
              )}
            </button>
          </div>

          {/* Submit */}
          <button
            type="submit"
            className="w-full bg-slate-900 text-white py-3 rounded-md font-bold transition hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Login as admin
          </button>
        </form>
      </div>
    </div>
  );
}

export default Login;
