from pyomo.environ import *
model = ConcreteModel()
model.x_1 = Var(within=NonNegativeReals)
model.C_prod_1=Var(within=NonNegativeReals)
model.x_2 = Var(within=NonNegativeReals)
model.C_prod_2=Var(within=NonNegativeReals)
model.con1 = Constraint(expr=model.x_1 + model.x_2 >= 1)
model.con2 = Constraint(expr=model.x_1 <= 0.6)
#
# -------------------------------------------------------
#
def f_Cfuel(model,x,eta):
    return x/f_eta(x)*50
#
def f_eta(x):
    return 0.3+x*0.2
#
# -------------------------------------------------------
#
model.obj = Objective(expr=model.x_1*4 + 2*model.x_2*8)
solver=SolverFactory('glpk')
results = solver.solve(model,tee=True)
print(value(model.x_1))
print(value(model.x_2))