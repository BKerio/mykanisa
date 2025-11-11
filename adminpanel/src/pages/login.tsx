// src/components/Login.tsx
import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import axios from 'axios';
import Swal from 'sweetalert2';
import {  Eye,  EyeOff,  ArrowLeft,  Mail,  Lock } from 'lucide-react';

import Admin_Avator from "@/assets/icon.png";

function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email || !password) {
      Swal.fire({
        icon: 'warning',
        title: 'Missing Fields',
        text: 'Please enter email and password.',
        confirmButtonColor: '#1A73E8',
      });
      return;
    }

    try {
      const res = await axios.post(`${import.meta.env.VITE_API_URL}/admin/login`, {
        email,
        password,
      });

      localStorage.setItem('token', res.data.token);

      Swal.fire({
        icon: 'success',
        title: 'Login successful!',
        confirmButtonText: 'OK',
        confirmButtonColor: '#1A73E8',
        allowOutsideClick: false,
        allowEscapeKey: false,
      }).then(() => {
        navigate('/dashboard');
      });
    } catch (err) {
      let errorMessage = 'Login failed. Please try again.';
      if (axios.isAxiosError(err)) {
        errorMessage = err.response?.data?.message || err.message || errorMessage;
      } else if (err instanceof Error) {
        errorMessage = err.message || errorMessage;
      }

      Swal.fire({
        icon: 'error',
        title: 'Login Failed',
        text: errorMessage,
        confirmButtonColor: '#E53935',
      });
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-100 via-purple-100 to-pink-100 px-4">
      <div className="relative bg-white/70 backdrop-blur-lg shadow-2xl rounded-xl w-full max-w-md p-8">
        {/* Go back */}
        <button
          onClick={() => navigate(-1)}
          className="absolute top-4 left-4 text-gray-600 p-1 rounded-full hover:bg-gray-200"
          aria-label="Go back"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>

        {/* Admin Avatar */}
        <div className="flex flex-col items-center mb-6 mt-2">
         <div className="flex flex-col items-center mb-6 mt-2">
           <div className="w-40 h-40 rounded-full overflow-hidden shadow-lg">
             <img
               src={Admin_Avator}
               alt="Admin Avatar"
               className="w-full h-full object-cover"
             />
           </div>
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
              placeholder="Admin email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full p-3 pl-10 border border-gray-300 rounded-md bg-white/80 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              required
            />
          </div>

          {/* Password Input */}
          <div className="relative">
            <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type={showPassword ? 'text' : 'password'}
              placeholder="Admin password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full p-3 pl-10 pr-10 border border-gray-300 rounded-md bg-white/80 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
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
            className="w-full bg-indigo-600 text-white py-3 rounded-md font-bold transition hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Login as Admin
          </button>
        </form>

        {/* Optional footer */}
        <p className="text-center text-sm text-gray-600 mt-6">
          Not an admin?{' '}
          <Link to="/" className="text-indigo-600 hover:underline font-medium">
            Go back to Home
          </Link>
        </p>
      </div>
    </div>
  );
}

export default Login;
