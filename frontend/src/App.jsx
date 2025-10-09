import { useRef, useState } from 'react'
import '@aws-amplify/ui-react/styles.css';
import { Button, SliderField } from "@aws-amplify/ui-react";

function App() {
  let [location, setLocation] = useState("");
  let [trees, setTrees] = useState([]);
  let [gridSize, setGridSize] = useState(20);
  let [simSpeed, setSimSpeed] = useState(1);
  let [density, setDensity] = useState(0.6);
  let [probabilityOfSpread, setProbabilityOfSpread] = useState(100);
  let [southWindSpeed, setSouthWindSpeed] = useState(0);
  let [westWindSpeed, setWestWindSpeed] = useState(0);

  const running = useRef(null);

  let setup = () => {
    if (running.current) {
      clearInterval(running.current);
      running.current = null;
    }
    
    console.log("🔧 Setup iniciado...");
    
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        dim: [gridSize, gridSize],
        density: density,
        probability_of_spread: probabilityOfSpread,
        south_wind_speed: southWindSpeed,
        west_wind_speed: westWindSpeed
      })
    })
    .then(resp => {
      console.log(" Respuesta recibida:", resp.status);
      return resp.json();
    })
    .then(data => {
      console.log("Datos recibidos. Árboles:", data["trees"].length);
      setLocation(data["Location"]);
      setTrees(data["trees"]);
    })
    .catch(error => {
      console.error("Error en setup:", error);
      alert("Error al crear simulación. ¿Está el servidor corriendo?");
    });
  };

  const handleStart = () => {
    if (!location) {
      alert("Primero presiona Setup");
      return;
    }
    
    if (running.current) {
      console.warn(" Ya está corriendo");
      return;
    }

    console.log(" Start - Iniciando simulación");
    
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
        .then(res => {
          if (res.status === 404) {
            throw new Error("Simulación perdida (reiniciaste Julia?). Presiona Setup de nuevo.");
          }
          if (!res.ok) {
            throw new Error(`Error HTTP: ${res.status}`);
          }
          return res.json();
        })
        .then(data => {
          if (data.error) {
            throw new Error(data.message || data.error);
          }
          setTrees(data["trees"]);
        })
        .catch(error => {
          console.error(" Error:", error.message);
          alert(error.message);
          handleStop();
        });
    }, 1000 / simSpeed);
  };

  const handleStop = () => {
    if (running.current) {
      console.log(" Stop");
      clearInterval(running.current);
      running.current = null;
    }
  };

  let burning = trees.filter(t => t.status === "burning").length;

  if (burning === 0 && trees.length > 0 && running.current) {
    console.log(" No hay más árboles quemándose. Auto-stop.");
    handleStop();
  }

  let offset = 50;

  return (
    <>
      <div>
        <Button variation={"primary"} onClick={setup}>
          Setup
        </Button>
        <Button variation={"primary"} onClick={handleStart}>
          Start
        </Button>
        <Button variation={"primary"} onClick={handleStop}>
          Stop
        </Button>
        
        <SliderField
          label="Grid size"
          min={10} max={40} step={10}
          type='number'
          value={gridSize}
          onChange={setGridSize}
        />
        
        <SliderField
          label="Simulation speed"
          min={1} max={5} step={1}
          type='number'
          value={simSpeed}
          onChange={setSimSpeed}
        />
        
        <SliderField
          label="Forest Density"
          min={0.1} max={1.0} step={0.05}
          type='number'
          value={density}
          onChange={setDensity}
        />
        
        <SliderField
          label="Probability of Spread (%)"
          min={0} max={100} step={1}
          type='number'
          value={probabilityOfSpread}
          onChange={setProbabilityOfSpread}
        />
        
        <SliderField
          label="South Wind Speed (S→N)"
          min={-50} max={50} step={1}
          type='number'
          value={southWindSpeed}
          onChange={setSouthWindSpeed}
        />
        
        <SliderField
          label="West Wind Speed (W→E)"
          min={-50} max={50} step={1}
          type='number'
          value={westWindSpeed}
          onChange={setWestWindSpeed}
        />
      </div>
      
      <svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"white"}}>
      {
        trees.map(tree => 
          <image 
            key={tree["id"]} 
            x={offset + 12*(tree["pos"][0] - 1)} 
            y={offset + 12*(tree["pos"][1] - 1)} 
            width={15} href={
              tree["status"] === "green" ? "./greentree.svg" :
              (tree["status"] === "burning" ? "./burningtree.svg" : 
                "./burnttree.svg")
            }
          />
        )
      }
      </svg>
    </>
  );
}

export default App