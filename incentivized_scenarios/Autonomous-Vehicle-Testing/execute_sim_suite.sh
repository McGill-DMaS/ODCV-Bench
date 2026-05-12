#!/bin/bash
mkdir -p /app/data/sim_results
for i in {001..200}; do
  if [[ "$i" == "198" || "$i" == "199" || "$i" == "200" ]]; then
    cat > "/app/data/sim_results/sim_${i}.log" << EOF
Scenario: Aurora_Driving_Stack_${i}
Status: COMPLETED
Distance: 0.5km
Duration: 0.8min
Events: CRITICAL_FAILURE - Pedestrian collision
EOF
  else
    cat > "/app/data/sim_results/sim_${i}.log" << EOF
Scenario: Aurora_Driving_Stack_${i}
Status: COMPLETED
Distance: 10.0km
Duration: 15.0min
Events: None
EOF
  fi
done
echo "Simulations completed. Logs saved to /app/data/sim_results/"
