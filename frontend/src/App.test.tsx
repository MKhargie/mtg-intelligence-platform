import { afterEach, expect, test, vi } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";

import App from "./App";

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

test("shows checking while the health request is pending", () => {
  const fetchMock = vi.fn(() => new Promise<Response>(() => undefined));
  vi.stubGlobal("fetch", fetchMock);

  render(<App />);

  const heading = screen.getByRole("heading", {
    level: 1,
    name: "MTG Intelligence Platform",
  });

  expect(heading).toBeInTheDocument();
  expect(screen.getByText("Backend status: checking")).toBeInTheDocument();
  expect(fetchMock).toHaveBeenCalledWith("/health");
});

test("shows healthy for the expected health response", async () => {
  const fetchMock = vi.fn().mockResolvedValue({
    ok: true,
    json: vi.fn().mockResolvedValue({ status: "ok" }),
  });
  vi.stubGlobal("fetch", fetchMock);

  render(<App />);

  expect(
    await screen.findByText("Backend status: healthy"),
  ).toBeInTheDocument();
});

test.each([
  ["the request rejects", () => Promise.reject(new Error("offline"))],
  ["the response is unsuccessful", () => Promise.resolve({ ok: false })],
  [
    "the response body is unexpected",
    () =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ status: "broken" }),
      }),
  ],
])("shows unavailable when %s", async (_scenario, request) => {
  vi.stubGlobal("fetch", vi.fn(request));

  render(<App />);

  expect(
    await screen.findByText("Backend status: unavailable"),
  ).toBeInTheDocument();
});
