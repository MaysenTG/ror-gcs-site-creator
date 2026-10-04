const { useState } = React;

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="app">
      <h1>Skeleton React</h1>
      <p>A tiny React starter loaded from a CDN. Edit script.js to grow this into your app.</p>
      <div className="counter">
        <strong>{count}</strong>
        <button type="button" onClick={() => setCount((value) => value + 1)}>
          Increment
        </button>
      </div>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App />);
