// src/components/WelcomePage.tsx
import { Link } from "react-router-dom";
import {  LucideHexagon } from "lucide-react";

const WelcomePage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-white via-gray-50 to-gray-100 flex flex-col justify-center items-center px-6 py-12 text-gray-800">

     

      {/* Card */}
      <div className="w-full max-w-md bg-white shadow-lg rounded-xl p-8 text-center hover:shadow-xl transition">

         {/* Branding */}
      <div className="text-center mb-6">
        <h1 className="text-3xl sm:text-3xl font-semibold ml-3 text-gray-800 align-text-bottom">
          PCEA Admin System
        </h1>
      </div>

      {/* Subtitle */}
      <p className="text-center text-gray-600 max-w-md mb-8 text-base sm:text-lg">
        Manage members, finances, and church records with ease and transparency.
      </p>
        <h3 className="text-xl font-semibold mb-6 text-indigo-700">Welcome Back!</h3>
        <Link
          to="/login"
          className="w-full bg-indigo-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-indigo-700 transition inline-flex items-center justify-center"
        >
          <LucideHexagon className="w-5 h-5 mr-2" /> Proceed as an Admin
        </Link>
      </div>

      {/* Footer */}
      <div className="mt-10 text-gray-700 text-sm flex items-center space-x-2 hover:text-indigo-600 transition">
      
        <span>
          Developed by <span className="font-medium">Millenium Solutions East Africa Ltd.</span>
        </span>
      </div>
    </div>
  );
};

export default WelcomePage;
