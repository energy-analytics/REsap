from pyomo.environ import *

from ReferenceModel import model

instance = model.create_instance("SmallGrowthTaperInstance.dat")


solver=SolverFactory('cplex')

results = solver.solve(instance,tee=True)

if False:

    import matplotlib.pyplot as plt

    plt.bar([0,1], [100,-20])
    plt.show()
