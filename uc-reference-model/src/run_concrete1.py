from pyomo.environ import *
from pyomo.dae import *


from concrete1 import model

instance = model.create_instance()

solver=SolverFactory('cplex')

results = solver.solve(instance,tee=True)


import matplotlib.pyplot as plt

plt.bar([0,1], [instance.x_1.value,instance.x_2.value])
plt.show()
