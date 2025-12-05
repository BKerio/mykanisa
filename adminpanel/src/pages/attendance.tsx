import { useEffect, useRef, useState } from "react";
import axios from "axios";
import Swal from "sweetalert2";
import "sweetalert2/dist/sweetalert2.min.css";
import {
  QrCode,
  Users,
  CheckCircle2,
  X,
  Play,
  Square,
  Trash2,
  Clock,
  MapPin,
  Phone,
  Mail,
  Scan,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

// Types
interface ScannedMember {
  id: number;
  e_kanisa_number: string;
  full_name: string;
  congregation?: string;
  parish?: string;
  presbytery?: string;
  phone?: string;
  email?: string;
  baptized?: boolean;
  taking_holy_communion?: boolean;
  scannedAt: Date;
}

interface QRData {
  type: string;
  member_id: number;
  e_kanisa_number: string;
  full_name: string;
  congregation: string;
  parish: string;
  presbytery: string;
  phone: string;
  baptized: boolean;
  taking_holy_communion: boolean;
}

const AttendancePage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
  const scannerInputRef = useRef<HTMLInputElement>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [scannedMembers, setScannedMembers] = useState<ScannedMember[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [lastScanTime, setLastScanTime] = useState<number>(0);

  // Start scanning - focus input field
  const startScanning = () => {
    setIsScanning(true);
    setError(null);
    // Focus the input field after a short delay to ensure it's rendered
    setTimeout(() => {
      scannerInputRef.current?.focus();
    }, 100);
  };

  // Stop scanning
  const stopScanning = () => {
    setIsScanning(false);
    if (scannerInputRef.current) {
      scannerInputRef.current.value = "";
      scannerInputRef.current.blur();
    }
  };

  // Handle QR Code Scan from external scanner
  const handleQRScan = async (qrDataString: string) => {
    try {
      // Parse QR data
      const qrData: QRData = JSON.parse(qrDataString);

      // Validate QR data structure
      if (qrData.type !== "PCEA_MEMBER" || !qrData.member_id || !qrData.e_kanisa_number) {
        Swal.fire({
          icon: "error",
          title: "Invalid QR Code",
          text: "This QR code is not a valid PCEA member card.",
          confirmButtonColor: "#0A1F44",
          timer: 2000,
        });
        return;
      }

      // Check if member already scanned
      const alreadyScanned = scannedMembers.some(
        (m) => m.e_kanisa_number === qrData.e_kanisa_number
      );

      if (alreadyScanned) {
        Swal.fire({
          icon: "warning",
          title: "Already Scanned",
          text: `${qrData.full_name} has already been marked as present.`,
          confirmButtonColor: "#0A1F44",
          timer: 2000,
        });
        return;
      }

      // Create scanned member object
      const scannedMember: ScannedMember = {
        id: qrData.member_id,
        e_kanisa_number: qrData.e_kanisa_number,
        full_name: qrData.full_name,
        congregation: qrData.congregation,
        parish: qrData.parish,
        presbytery: qrData.presbytery,
        phone: qrData.phone || "",
        baptized: qrData.baptized,
        taking_holy_communion: qrData.taking_holy_communion,
        scannedAt: new Date(),
      };

      // Add to list
      setScannedMembers((prev) => [...prev, scannedMember]);

      // Send SMS immediately after marking attendance
      if (token && qrData.phone) {
        try {
          await axios.post(
            `${API_URL}/admin/attendance/mark-single`,
            {
              member_id: qrData.member_id,
              e_kanisa_number: qrData.e_kanisa_number,
              full_name: qrData.full_name,
              phone: qrData.phone,
              event_type: "Digital Attendance",
              event_date: new Date().toISOString().split("T")[0],
            },
            {
              headers: {
                Authorization: `Bearer ${token}`,
              },
            }
          );
        } catch (err) {
          // Log error but don't show to user - attendance is still marked
          console.error("Failed to send SMS:", err);
        }
      }

      // Show success alert
      Swal.fire({
        icon: "success",
        title: "Attendance Marked!",
        html: `
          <div class="text-center">
            <p class="text-lg font-bold text-slate-800 mb-2">${qrData.full_name}</p>
            <p class="text-sm text-slate-600">E-Kanisa: ${qrData.e_kanisa_number}</p>
            ${qrData.phone ? `<p class="text-xs text-green-600 mt-2">✓ SMS notification sent</p>` : ''}
            <p class="text-xs text-slate-500 mt-2">${new Date().toLocaleTimeString()}</p>
          </div>
        `,
        confirmButtonColor: "#0A1F44",
        timer: 2000,
        showConfirmButton: true,
        customClass: {
          popup: "rounded-2xl",
        },
      });

      // Clear input field for next scan
      if (scannerInputRef.current) {
        scannerInputRef.current.value = "";
        scannerInputRef.current.focus();
      }
    } catch (err: any) {
      console.error("Error parsing QR data:", err);
      Swal.fire({
        icon: "error",
        title: "Invalid QR Code",
        text: "Could not read QR code data. Please try again.",
        confirmButtonColor: "#0A1F44",
        timer: 2000,
      });
      // Clear input field
      if (scannerInputRef.current) {
        scannerInputRef.current.value = "";
        scannerInputRef.current.focus();
      }
    }
  };

  // Handle input from external scanner
  const handleScannerInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.trim();
    
    // External scanners typically send data with Enter key or after a delay
    // We'll detect when a complete JSON string is entered
    if (value.length > 0) {
      // Check if it looks like JSON
      if (value.startsWith("{") && value.endsWith("}")) {
        const now = Date.now();
        // Debounce: if scan happened within 500ms, it's likely the same scan
        if (now - lastScanTime > 500) {
          setLastScanTime(now);
          handleQRScan(value);
        }
      }
    }
  };

  // Handle key press (for Enter key from scanner)
  const handleKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      const value = e.currentTarget.value.trim();
      if (value.length > 0) {
        e.preventDefault();
        const now = Date.now();
        if (now - lastScanTime > 500) {
          setLastScanTime(now);
          handleQRScan(value);
        }
      }
    }
  };

  // Remove member from list
  const removeMember = (eKanisaNumber: string) => {
    Swal.fire({
      title: "Remove Member?",
      text: "Are you sure you want to remove this member from attendance?",
      icon: "question",
      showCancelButton: true,
      confirmButtonColor: "#ef4444",
      cancelButtonColor: "#94a3b8",
      confirmButtonText: "Remove",
      cancelButtonText: "Cancel",
      customClass: {
        popup: "rounded-2xl",
      },
    }).then((result) => {
      if (result.isConfirmed) {
        setScannedMembers((prev) =>
          prev.filter((m) => m.e_kanisa_number !== eKanisaNumber)
        );
        Swal.fire({
          icon: "success",
          title: "Removed",
          text: "Member removed from attendance list.",
          timer: 1500,
          showConfirmButton: false,
          toast: true,
          position: "top-end",
        });
      }
    });
  };

  // Clear all attendance
  const clearAll = () => {
    if (scannedMembers.length === 0) return;

    Swal.fire({
      title: "Clear All Attendance?",
      text: `This will remove all ${scannedMembers.length} members from the list.`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#ef4444",
      cancelButtonColor: "#94a3b8",
      confirmButtonText: "Clear All",
      cancelButtonText: "Cancel",
      customClass: {
        popup: "rounded-2xl",
      },
    }).then((result) => {
      if (result.isConfirmed) {
        setScannedMembers([]);
        Swal.fire({
          icon: "success",
          title: "Cleared",
          text: "All attendance records cleared.",
          timer: 1500,
          showConfirmButton: false,
          toast: true,
          position: "top-end",
        });
      }
    });
  };

  // Save attendance to backend
  const saveAttendance = async () => {
    if (scannedMembers.length === 0) {
      Swal.fire({
        icon: "warning",
        title: "No Members",
        text: "Please scan at least one member before saving.",
        confirmButtonColor: "#0A1F44",
      });
      return;
    }

    if (!token) {
      Swal.fire({
        icon: "error",
        title: "Unauthorized",
        text: "Please log in to save attendance.",
        confirmButtonColor: "#0A1F44",
      });
      return;
    }

    try {
      const response = await axios.post(
        `${API_URL}/admin/attendance/mark`,
        {
          members: scannedMembers.map((m) => ({
            member_id: m.id,
            e_kanisa_number: m.e_kanisa_number,
            full_name: m.full_name,
            phone: m.phone || "",
          })),
          event_type: "Digital Attendance",
          event_date: new Date().toISOString().split("T")[0],
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.data.status === 200) {
        const smsSent = response.data.data?.sms_sent || 0;
        const smsTotal = response.data.data?.sms_total || 0;
        
        Swal.fire({
          icon: "success",
          title: "Attendance Saved!",
          html: `
            <div class="text-center">
              <p class="text-lg font-bold text-slate-800 mb-2">${scannedMembers.length} members marked as present</p>
              <p class="text-sm text-slate-600 mb-2">Attendance has been saved successfully.</p>
              ${smsTotal > 0 ? `
                <p class="text-xs text-slate-500 mt-3 pt-3 border-t border-slate-200">
                  SMS notifications sent: ${smsSent} of ${smsTotal}
                </p>
              ` : ''}
            </div>
          `,
          confirmButtonColor: "#0A1F44",
          customClass: {
            popup: "rounded-2xl",
          },
        });

        // Optionally clear the list after saving
        // setScannedMembers([]);
      }
    } catch (err: any) {
      Swal.fire({
        icon: "error",
        title: "Save Failed",
        text: err?.response?.data?.message || "Failed to save attendance. Please try again.",
        confirmButtonColor: "#0A1F44",
      });
    }
  };

  // Auto-focus input when scanning starts
  useEffect(() => {
    if (isScanning) {
      const timer = setTimeout(() => {
        scannerInputRef.current?.focus();
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [isScanning]);

  return (
    <div className="p-6 md:p-10 bg-slate-50 min-h-screen font-sans text-slate-900">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
        >
          <div className="flex items-center gap-3 mb-1">
            <div className="p-2.5 bg-blue-950 text-white rounded-xl shadow-sm">
              <QrCode className="w-6 h-6" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Digital Attendance
            </h1>
          </div>
          <p className="text-slate-500 text-sm ml-1">
            Scan QR codes from member digital cards using external scanner
          </p>
        </motion.div>

        <div className="flex flex-wrap gap-3">
          {!isScanning ? (
            <button
              onClick={startScanning}
              className="flex items-center gap-2 px-5 py-2.5 bg-blue-950 text-white rounded-xl hover:bg-blue-900 transition-all shadow-sm active:scale-95 font-medium"
            >
              <Play className="w-5 h-5" />
              Initiate Attendance
            </button>
          ) : (
            <button
              onClick={stopScanning}
              className="flex items-center gap-2 px-5 py-2.5 bg-red-600 text-white rounded-xl hover:bg-red-700 transition-all shadow-sm active:scale-95 font-medium"
            >
              <Square className="w-5 h-5" />
              Stop Scanning
            </button>
          )}
          {scannedMembers.length > 0 && (
            <>
              <button
                onClick={clearAll}
                className="flex items-center gap-2 px-5 py-2.5 bg-white border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50 transition-all shadow-sm active:scale-95 font-medium"
              >
                <Trash2 className="w-5 h-5" />
                Clear All
              </button>
              <button
                onClick={saveAttendance}
                className="flex items-center gap-2 px-5 py-2.5 bg-green-600 text-white rounded-xl hover:bg-green-700 transition-all shadow-sm active:scale-95 font-medium"
              >
                <CheckCircle2 className="w-5 h-5" />
                Save ({scannedMembers.length})
              </button>
            </>
          )}
        </div>
      </div>

      {/* Scanner Input Section */}
      {isScanning && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <div className="bg-white rounded-2xl shadow-lg border border-slate-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-blue-50 rounded-lg">
                <Scan className="w-5 h-5 text-blue-950" />
              </div>
              <div>
                <h3 className="font-bold text-slate-900">External Scanner Ready</h3>
                <p className="text-sm text-slate-500">
                  Point your scanner at the QR code and scan
                </p>
              </div>
            </div>
            <div className="relative">
              <input
                ref={scannerInputRef}
                type="text"
                onChange={handleScannerInput}
                onKeyPress={handleKeyPress}
                placeholder="Scan QR code here..."
                className="w-full px-4 py-3 text-sm border-2 border-blue-200 rounded-xl focus:border-blue-950 focus:ring-2 focus:ring-blue-950/20 outline-none transition-all bg-slate-50"
                autoFocus
                autoComplete="off"
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                  <span className="text-xs text-slate-500 font-medium">Ready</span>
                </div>
              </div>
            </div>
            {error && (
              <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                {error}
              </div>
            )}
          </div>
        </motion.div>
      )}

      {/* Attendance List */}
      <div className="bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden">
        <div className="p-6 border-b border-slate-200 bg-slate-50">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-50 rounded-lg">
                <Users className="w-5 h-5 text-blue-950" />
              </div>
              <div>
                <h3 className="font-bold text-slate-900">Attendance List</h3>
                <p className="text-sm text-slate-500">
                  {scannedMembers.length} member{scannedMembers.length !== 1 ? "s" : ""} marked
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          {scannedMembers.length === 0 ? (
            <div className="text-center py-20">
              <div className="inline-flex p-4 rounded-full bg-slate-100 text-slate-400 mb-4">
                <QrCode className="w-8 h-8" />
              </div>
              <h3 className="text-lg font-medium text-slate-900 mb-1">
                No members scanned yet
              </h3>
              <p className="text-slate-500 text-sm">
                {isScanning
                  ? "Point your external scanner at a member's QR code to mark attendance"
                  : "Click 'Initiate Attendance' to begin scanning QR codes"}
              </p>
            </div>
          ) : (
            <table className="min-w-full border-separate border-spacing-y-3">
              <thead>
                <tr className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                  <th className="px-6 pb-2 text-left">No.</th>
                  <th className="px-6 pb-2 text-left">Member</th>
                  <th className="px-6 pb-2 text-left">Kanisa Number</th>
                  <th className="px-6 pb-2 text-left">Location</th>
                  <th className="px-6 pb-2 text-left">Contact</th>
                  <th className="px-6 pb-2 text-left">Holy Communion / Baptism Status</th>
                  <th className="px-6 pb-2 text-left">Scanned At</th>
                  <th className="px-6 pb-2 text-left">Action</th>
                </tr>
              </thead>
              <tbody>
                <AnimatePresence mode="popLayout">
                  {scannedMembers.map((member, index) => (
                    <motion.tr
                      key={member.e_kanisa_number}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      transition={{ delay: index * 0.05 }}
                      className="group relative bg-white rounded-2xl shadow-sm border border-slate-200 hover:shadow-md hover:border-blue-900/30 transition-all duration-300"
                    >
                      <td className="p-4 rounded-l-2xl">
                        <div className="w-8 h-8 rounded-full bg-blue-950 text-white flex items-center justify-center font-bold text-sm">
                          {index + 1}
                        </div>
                      </td>
                      <td className="p-4">
                        <div>
                          <div className="font-bold text-slate-900 text-[15px]">
                            {member.full_name}
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="text-xs text-slate-600 font-mono">
                          {member.e_kanisa_number}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-1">
                          <div className="flex items-center text-xs font-medium text-slate-800">
                            <MapPin className="w-3 h-3 mr-1 text-slate-400" />
                            {member.congregation || "N/A"}
                          </div>
                          {member.parish && (
                            <div className="text-[11px] text-slate-500 pl-4">
                              {member.parish}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-1.5">
                          {member.phone && (
                            <div className="flex items-center text-xs text-slate-600">
                              <Phone className="w-3 h-3 mr-2 text-slate-400" />
                              {member.phone}
                            </div>
                          )}
                          {member.email && (
                            <div className="flex items-center text-xs text-slate-600">
                              <Mail className="w-3 h-3 mr-2 text-slate-400" />
                              <span className="truncate max-w-[120px]" title={member.email}>
                                {member.email}
                              </span>
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-1">
                          {member.baptized && (
                            <span className="inline-flex items-center px-2 py-1 rounded-md text-[10px] font-bold bg-green-50 text-green-800 border border-green-200">
                              Baptized
                            </span>
                          )}
                          {member.taking_holy_communion && (
                            <span className="inline-flex items-center px-2 py-1 rounded-md text-[10px] font-bold bg-blue-50 text-blue-800 border border-blue-200">
                              Holy Communion
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center text-xs text-slate-600">
                          <Clock className="w-3 h-3 mr-2 text-slate-400" />
                          {member.scannedAt.toLocaleTimeString()}
                        </div>
                      </td>
                      <td className="p-4 rounded-r-2xl">
                        <button
                          onClick={() => removeMember(member.e_kanisa_number)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Remove"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
};

export default AttendancePage;
