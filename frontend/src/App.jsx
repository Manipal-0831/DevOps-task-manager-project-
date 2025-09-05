import { useEffect, useState } from "react";
import axios from "axios";

const API_URL = "http://localhost:8000";

export default function App() {
  const [files, setFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [file, setFile] = useState(null);
  const [health, setHealth] = useState(null);

  const refresh = async () => {
    const r = await axios.get(`${API_URL}/files`);
    setFiles(r.data.files || []);
  };

  useEffect(() => {
    axios.get(`${API_URL}/health`).then(r => setHealth(r.data.status)).catch(()=>setHealth("fail"));
    refresh();
  }, []);

  const doUpload = async () => {
    if (!file) return;
    setUploading(true);
    const form = new FormData();
    form.append("file", file);
    await axios.post(`${API_URL}/upload`, form, {
      headers: {"Content-Type":"multipart/form-data"}
    });
    setUploading(false);
    setFile(null);
    await refresh();
  };

  return (
    <div style={{maxWidth: 800, margin: "40px auto", fontFamily: "sans-serif"}}>
      <h1>File Uploader</h1>
      <h4>upload Task</h4>
      <p>Backend health: <b>{health || "..."}</b></p>
      <div style={{display:"flex", gap:12, alignItems:"center"}}>
        <input type="file" onChange={e=>setFile(e.target.files?.[0]||null)}/>
        <button onClick={doUpload} disabled={!file || uploading}>
          {uploading ? "Uploading..." : "Upload"}
        </button>
      </div>
      <h3 style={{marginTop:24}}>Files in S3 (LocalStack):</h3>
      <ul>
        {files.map(f => <li key={f.key}>{f.key} — {f.size} bytes</li>)}
      </ul>
    </div>
  );
}
