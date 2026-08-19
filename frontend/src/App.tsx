import { useEffect, useState } from "react";

type HealthStatus = "checking" | "healthy" | "unavailable";

function App() {
  const [healthStatus, setHealthStatus] = useState<HealthStatus>("checking");

  useEffect(() => {
    async function checkBackendHealth() {
      try {
        const response = await fetch("/health");

        if (!response.ok) {
          setHealthStatus("unavailable");
          return;
        }

        const body: unknown = await response.json();
        const isHealthy =
          typeof body === "object" &&
          body !== null &&
          "status" in body &&
          body.status === "ok";

        setHealthStatus(isHealthy ? "healthy" : "unavailable");
      } catch {
        setHealthStatus("unavailable");
      }
    }

    void checkBackendHealth();
  }, []);

  return (
    <section id="center">
      <div>
        <h1>MTG Intelligence Platform</h1>
        <p>Backend status: {healthStatus}</p>
      </div>
    </section>
  );
}

export default App;
