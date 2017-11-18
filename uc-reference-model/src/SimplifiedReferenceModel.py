from pyomo.core import *

model = AbstractModel()
#
# Parameters
model.ThermalGenerators = Set()
model.NumTimePeriods = Param(within=PositiveIntegers)
model.TimePeriods = RangeSet(1, model.NumTimePeriods)
model.Demand = Param(model.TimePeriods, within=NonNegativeReals)
model.MinimumPowerOutput = Param(model.ThermalGenerators, within=NonNegativeReals, default=0.0)

def maximum_power_output_validator(m, v, g):
    return v >= value(m.MinimumPowerOutput[g])

model.MaximumPowerOutput = Param(model.ThermalGenerators, within=NonNegativeReals,
                                 validate=maximum_power_output_validator)

model.Cost = Param(model.ThermalGenerators, within=NonNegativeReals)
#
#  decision variables
model.UnitOn = Var(model.ThermalGenerators, model.TimePeriods, within=Binary)
model.PowerGenerated = Var(model.ThermalGenerators, model.TimePeriods, within=NonNegativeReals)
#
# Constraints

def production_equals_demand_rule(m, t):
    return sum(m.PowerGenerated[g, t] for g in m.ThermalGenerators) == m.Demand[t]

model.ProductionEqualsDemand = Constraint(model.TimePeriods, rule=production_equals_demand_rule)

def enforce_generator_output_limits_rule_part_a(m, g, t):
    return m.MinimumPowerOutput[g] * m.UnitOn[g, t] <= m.PowerGenerated[g, t]

model.EnforceGeneratorOutputLimitsPartA = Constraint(model.ThermalGenerators, model.TimePeriods,
                                                     rule=enforce_generator_output_limits_rule_part_a)


#
# Objectives
def total_cost_objective_rule(m):
    return sum(sum(m.PowerGenerated[g,t] for t in m.TimePeriods) * m.Cost[g] for g in m.ThermalGenerators)


model.TotalCostObjective = Objective(rule=total_cost_objective_rule, sense=minimize)
