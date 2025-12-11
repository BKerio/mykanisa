import { useEffect, useRef, useState } from "react";
import axios from "axios";
import Swal from "sweetalert2";
import "sweetalert2/dist/sweetalert2.min.css";
import {
  QrCode,
  Users,
  Play,
  Square,
  Clock,
  MapPin,
  Scan,
  FileSpreadsheet,
  FileText,
  CalendarDays,
  RefreshCw,
  ChevronDown,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import dayjs from "dayjs";
import * as XLSX from "xlsx";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

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
  event_type?: string;
  event_date?: string;
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

const EVENT_TYPES = ["Sunday Service", "Holy Communion", "Weekly Meeting", "AGM", "Other"];

const AttendancePage = () => {
  const API_URL = import.meta.env.VITE_API_URL;
  const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
  const scannerInputRef = useRef<HTMLInputElement>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [scannedMembers, setScannedMembers] = useState<ScannedMember[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [lastScanTime, setLastScanTime] = useState<number>(0);

  // Timer State
  const [scanEndTime, setScanEndTime] = useState<number | null>(null);
  const [timeLeft, setTimeLeft] = useState<string>("");

  // Date Filters
  const [startDate, setStartDate] = useState(dayjs().format('YYYY-MM-DD'));
  const [endDate, setEndDate] = useState(dayjs().format('YYYY-MM-DD'));
  const [isLoading, setIsLoading] = useState(false);

  // Event Selection
  const [selectedEventType, setSelectedEventType] = useState("Sunday Service");
  const [customEventType, setCustomEventType] = useState("");

  // Fetch Attendance Data
  const fetchAttendance = async () => {
    if (!token) return;
    setIsLoading(true);
    try {
      const response = await axios.get(`${API_URL}/admin/attendance`, {
        params: {
          start_date: startDate,
          end_date: endDate,
        },
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.data.data) {
        const mappedData = response.data.data.map((item: any) => ({
          id: item.member_id,
          e_kanisa_number: item.e_kanisa_number,
          full_name: item.full_name,
          congregation: item.congregation,
          scannedAt: new Date(item.scanned_at),
          event_type: item.event_type,
          event_date: item.event_date,
          // Map other fields if available in backend response, otherwise they might be missing
          phone: "",
          email: "",
          baptized: false,
          taking_holy_communion: false
        }));
        setScannedMembers(mappedData);
      }
    } catch (err) {
      console.error("Failed to fetch attendance:", err);
      // Don't alert on initial load if empty, just log
    } finally {
      setIsLoading(false);
    }
  };

  // Initial Fetch on Date Change or Mount
  useEffect(() => {
    fetchAttendance();
  }, [startDate, endDate]);


  // Start scanning - focus input field
  const startScanning = async () => {
    // Ask for duration
    const { value: minutes } = await Swal.fire({
      title: 'Set Session Duration',
      input: 'number',
      inputLabel: 'Enter duration in minutes',
      inputPlaceholder: 'e.g., 60',
      inputValue: 60,
      showCancelButton: true,
      confirmButtonColor: '#0A1F44',
      cancelButtonColor: '#d33',
      confirmButtonText: 'Start Session',
      inputValidator: (value) => {
        if (!value || parseInt(value) <= 0) {
          return 'Please enter a valid duration (greater than 0)';
        }
        return null;
      }
    });

    if (minutes) {
      const duration = parseInt(minutes) * 60 * 1000;
      const endTime = Date.now() + duration;
      setScanEndTime(endTime);

      setIsScanning(true);
      setError(null);
      // Focus the input field after a short delay to ensure it's rendered
      setTimeout(() => {
        scannerInputRef.current?.focus();
      }, 100);
    }
  };

  // Timer Effect
  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (isScanning && scanEndTime) {
      interval = setInterval(() => {
        const now = Date.now();
        const diff = scanEndTime - now;

        if (diff <= 0) {
          // Time Expired
          clearInterval(interval);
          stopScanning();
          Swal.fire({
            icon: 'info',
            title: 'Session Ended',
            text: 'The allocated time for attendance taking has ellapsed.',
            confirmButtonColor: '#0A1F44'
          });
          setTimeLeft("00:00");
        } else {
          // Format time left
          const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
          const seconds = Math.floor((diff % (1000 * 60)) / 1000);
          setTimeLeft(`${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`);
        }
      }, 1000);
    }

    return () => clearInterval(interval);
  }, [isScanning, scanEndTime]);

  // Stop scanning
  const stopScanning = () => {
    setIsScanning(false);
    setScanEndTime(null); // Reset timer
    setTimeLeft("");
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

      // Check Time Expiry (Double check)
      if (scanEndTime && Date.now() > scanEndTime) {
        stopScanning();
        Swal.fire({
          icon: 'error',
          title: 'Time Expired',
          text: 'Cannot process scan. The session has ended.',
          confirmButtonColor: '#0A1F44'
        });
        return;
      }

      // Determine final event type
      const finalEventType = selectedEventType === "Other" ? customEventType : selectedEventType;

      if (!finalEventType) {
        Swal.fire({
          icon: "warning",
          title: "Event Type Required",
          text: "Please enter an event name for 'Other'.",
          confirmButtonColor: "#0A1F44",
        });
        return;
      }

      // --- VALIDATION LOGIC ---
      if (selectedEventType === "Holy Communion") {
        // Check eligibility
        if (!qrData.baptized || !qrData.taking_holy_communion) {
          Swal.fire({
            icon: "error",
            title: "Not Eligible",
            html: `
                    <div class="text-center">
                        <p class="mb-2">Member <b>${qrData.full_name}</b> is not eligible for Holy Communion.</p>
                        <div class="flex flex-col gap-1 text-sm text-red-600 bg-red-50 p-3 rounded-lg text-left">
                            <p>• Baptized: <b>${qrData.baptized ? "Yes" : "No"}</b></p>
                            <p>• Taking Communion: <b>${qrData.taking_holy_communion ? "Yes" : "No"}</b></p>
                        </div>
                    </div>
                  `,
            confirmButtonColor: "#EF4444", // Red
          });

          // Clear input and refocus
          if (scannerInputRef.current) {
            scannerInputRef.current.value = "";
            scannerInputRef.current.focus();
          }
          return; // STOP execution
        }
      }

      // Send immediate request to mark single attendance
      if (token) {
        try {
          const res = await axios.post(
            `${API_URL}/admin/attendance/mark-single`,
            {
              member_id: qrData.member_id,
              e_kanisa_number: qrData.e_kanisa_number,
              full_name: qrData.full_name,
              phone: qrData.phone,
              event_type: finalEventType,
              event_date: new Date().toISOString().split("T")[0],
            },
            {
              headers: {
                Authorization: `Bearer ${token}`,
              },
            }
          );

          if (res.data.status === 200) {
            const isNew = res.data.data.was_recently_created;

            if (isNew) {
              // SUCCESS - New Scan
              Swal.fire({
                icon: "success",
                title: "Attendance Marked!",
                html: `
                      <div class="text-center">
                        <p class="text-lg font-bold text-slate-800 mb-2">${qrData.full_name}</p>
                        <p class="text-sm text-slate-600">E-Kanisa: ${qrData.e_kanisa_number}</p>
                        <p class="text-xs text-blue-800 font-semibold mt-1 bg-blue-50 inline-block px-2 py-0.5 rounded">${finalEventType}</p>
                        ${res.data.data.sms_sent ? `<p class="text-xs text-green-600 mt-2">✓ SMS notification sent</p>` : ''}
                      </div>
                    `,
                confirmButtonColor: "#0A1F44",
                timer: 2000,
                showConfirmButton: false,
                customClass: {
                  popup: "rounded-2xl",
                },
              });
            } else {
              // WARNING - Already Marked
              Swal.fire({
                icon: "warning",
                title: "Already Marked",
                html: `
                      <div class="text-center">
                        <p class="mb-2 text-slate-600">Member <b>${qrData.full_name}</b> is already marked present for:</p>
                        <p class="font-bold text-slate-800">${finalEventType}</p>
                        <p class="text-xs text-slate-400 mt-2">No duplicate SMS sent.</p>
                      </div>
                    `,
                confirmButtonColor: "#F59E0B", // Amber-500
                timer: 2500,
                showConfirmButton: false,
                customClass: {
                  popup: "rounded-2xl border-2 border-amber-100",
                },
              });
            }

            // Refresh list to show new addition
            fetchAttendance();
          }

        } catch (err: any) {
          console.error("Failed to mark attendance:", err);
          Swal.fire({
            icon: "error",
            title: "Error",
            text: err?.response?.data?.message || "Failed to mark attendance.",
            confirmButtonColor: "#0A1F44",
          });
        }
      }

      // Clear input field for next scan
      if (scannerInputRef.current) {
        scannerInputRef.current.value = "";
        scannerInputRef.current.focus();
      }
    } catch (err: any) {
      console.error("Error parsing QR data:", err);
      // Only show error if it looks like a failed parse of a JSON string, ignore empty/partial scans
      if (qrDataString.trim().startsWith('{')) {
        Swal.fire({
          icon: "error",
          title: "Invalid QR Code",
          text: "Could not read QR code data. Please try again.",
          confirmButtonColor: "#0A1F44",
          timer: 2000,
        });
      }
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


  // Export to Excel
  const exportToExcel = () => {
    if (scannedMembers.length === 0) {
      Swal.fire("No Data", "There is no attendance data to export.", "info");
      return;
    }

    const dataToExport = scannedMembers.map((m, index) => ({
      "No.": index + 1,
      "Full Name": m.full_name,
      "E-Kanisa Number": m.e_kanisa_number,
      "Congregation": m.congregation || "N/A",
      "Event Type": m.event_type || "N/A",
      "Event Date": m.event_date || "N/A",
      "Time Scanned": dayjs(m.scannedAt).format("HH:mm:ss"),
      "Date Scanned": dayjs(m.scannedAt).format("YYYY-MM-DD"),
    }));

    const ws = XLSX.utils.json_to_sheet(dataToExport);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Attendance");

    const fileName = `Attendance_Report_${startDate}_to_${endDate}.xlsx`;
    XLSX.writeFile(wb, fileName);
  };

  // Export to PDF
  const exportToPDF = () => {
    if (scannedMembers.length === 0) {
      Swal.fire("No Data", "There is no attendance data to export.", "info");
      return;
    }

    const doc = new jsPDF();

    // Add Title
    doc.setFontSize(18);
    doc.text("PCEA Church - Attendance Report", 14, 20);

    doc.setFontSize(11);
    doc.setTextColor(100);
    doc.text(`Period: ${startDate} to ${endDate}`, 14, 30);
    doc.text(`Generated: ${dayjs().format("DD MMM YYYY, HH:mm")}`, 14, 36);

    const tableColumn = ["No.", "Name", "E-Kanisa", "Congregation", "Event", "Date", "Time"];
    const tableRows = scannedMembers.map((m, index) => [
      index + 1,
      m.full_name,
      m.e_kanisa_number,
      m.congregation || "-",
      m.event_type || "-",
      m.event_date || "-",
      dayjs(m.scannedAt).format("HH:mm"),
    ]);

    autoTable(doc, {
      head: [tableColumn],
      body: tableRows,
      startY: 45,
      theme: 'grid',
      styles: { fontSize: 9 },
      headStyles: { fillColor: [10, 31, 68] }, // Blue-950
    });

    doc.save(`Attendance_Report_${startDate}_to_${endDate}.pdf`);
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
            Scan QR codes and manage attendance records
          </p>

          {isScanning && timeLeft && (
            <div className="mt-3 inline-flex items-center gap-2 px-3 py-1.5 bg-red-50 text-red-700 rounded-lg border border-red-100 animate-pulse">
              <Clock className="w-4 h-4" />
              <span className="text-sm font-bold font-mono">{timeLeft} remaining</span>
            </div>
          )}

        </motion.div>

        <div className="flex flex-wrap gap-3 items-center">

          {/* Event Type Selection */}
          <div className="flex items-center gap-2">
            <div className="relative">
              <select
                value={selectedEventType}
                onChange={(e) => setSelectedEventType(e.target.value)}
                className="appearance-none pl-3 pr-8 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-700 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-950/20"
              >
                {EVENT_TYPES.map(type => (
                  <option key={type} value={type}>{type}</option>
                ))}
              </select>
              <ChevronDown className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
            </div>

            {selectedEventType === "Other" && (
              <input
                type="text"
                placeholder="Enter Event Name"
                value={customEventType}
                onChange={(e) => setCustomEventType(e.target.value)}
                className="w-40 px-3 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-700 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-950/20"
              />
            )}
          </div>

          {/* Filters */}
          <div className="flex items-center bg-white p-1 rounded-xl border border-slate-200 shadow-sm h-[42px]">
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <CalendarDays className="h-4 w-4 text-slate-400" />
              </div>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="pl-9 pr-3 py-1.5 text-sm border-none bg-transparent focus:ring-0 text-slate-700"
              />
            </div>
            <span className="text-slate-300">-</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="pl-3 pr-3 py-1.5 text-sm border-none bg-transparent focus:ring-0 text-slate-700"
            />
            <button
              onClick={fetchAttendance}
              className="p-1.5 hover:bg-slate-100 rounded-lg text-slate-500 transition-colors"
              title="Refresh"
            >
              <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
            </button>
          </div>

          {!isScanning ? (
            <button
              onClick={startScanning}
              className="flex items-center gap-2 px-5 py-2.5 bg-blue-950 text-white rounded-xl hover:bg-blue-900 transition-all shadow-sm active:scale-95 font-medium"
            >
              <Play className="w-5 h-5" />
              Start Scanning
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
        </div>
      </div>

      {/* Actions Bar */}
      <div className="flex justify-end gap-3 mb-6">
        <button
          onClick={exportToExcel}
          disabled={scannedMembers.length === 0}
          className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
        >
          <FileSpreadsheet className="w-4 h-4" />
          Export Excel
        </button>
        <button
          onClick={exportToPDF}
          disabled={scannedMembers.length === 0}
          className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
        >
          <FileText className="w-4 h-4" />
          Export PDF
        </button>
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
              <div className="flex-1">
                <h3 className="font-bold text-slate-900">External Scanner Ready</h3>
                <p className="text-sm text-slate-500">
                  Scanning for event: <span className="font-bold text-blue-900">{selectedEventType === "Other" ? customEventType : selectedEventType}</span>
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
                  {scannedMembers.length} record{scannedMembers.length !== 1 ? "s" : ""} found
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
                No attendance records found
              </h3>
              <p className="text-slate-500 text-sm">
                {isScanning
                  ? "Scan a QR code to mark attendance"
                  : "Try adjusting the date filters or start scanning"}
              </p>
            </div>
          ) : (
            <table className="min-w-full border-separate border-spacing-y-3">
              <thead>
                <tr className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                  <th className="px-6 pb-2 text-left">No.</th>
                  <th className="px-6 pb-2 text-left">Member</th>
                  <th className="px-6 pb-2 text-left">Kanisa Number</th>
                  <th className="px-6 pb-2 text-left">Event</th>
                  <th className="px-6 pb-2 text-left">Location</th>
                  <th className="px-6 pb-2 text-left">Scanned At</th>
                </tr>
              </thead>
              <tbody>
                <AnimatePresence mode="popLayout">
                  {scannedMembers.map((member, index) => (
                    <motion.tr
                      key={`${member.e_kanisa_number}-${index}`}
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
                        <div className="flex flex-col">
                          <span className="text-sm font-medium text-slate-800">{member.event_type}</span>
                          <span className="text-xs text-slate-500">{member.event_date}</span>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-1">
                          <div className="flex items-center text-xs font-medium text-slate-800">
                            <MapPin className="w-3 h-3 mr-1 text-slate-400" />
                            {member.congregation || "N/A"}
                          </div>
                        </div>
                      </td>
                      <td className="p-4 rounded-r-2xl">
                        <div className="flex items-center text-xs text-slate-600">
                          <Clock className="w-3 h-3 mr-2 text-slate-400" />
                          {dayjs(member.scannedAt).format("HH:mm:ss")}
                        </div>
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
