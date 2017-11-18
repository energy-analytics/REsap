from pyomo.environ import *
from pyomo.opt import SolverFactory
from concrete1 import model


model.pprint()

with SolverFactory("glpk") as opt:
    results = opt.solve(model, load_solutions=False)

