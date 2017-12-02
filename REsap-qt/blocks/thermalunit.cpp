#include "thermalunit.h"

Block_ThermalUnit::Block_ThermalUnit(QGraphicsItem *parent) : BuildingBlock(parent)
{
    setLabelText(QObject::tr("Thermal Unit"));
    setPixmap(QPixmap(":/resources/icons/powerplant.png"));
    addPort(Port(QObject::tr("Power production"), Port::Out, Port::Left));
}
