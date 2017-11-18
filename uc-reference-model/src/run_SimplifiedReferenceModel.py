from pyomo.environ import *
from MinimalExample_LinerizedCost import model

instance = model.create_instance("SimplifiedLinerized.dat")
solver = SolverFactory('glpk')
results = solver.solve(instance, tee=True)

if False:
    import matplotlib.pyplot as plt

    plt.bar([0, 1], [100, -20])
    plt.plot(range(1, instance.NumTimePeriods.value + 1), instance.Demand._data.values())

    u = []
    for i in range(1, 5):
        u.append(instance.PowerGenerated._data['Unit1', i].value)

    plt.plot(range(1, instance.NumTimePeriods.value + 1), u)
    plt.show()

    # instance.Demand._data.values()
