#include "predatorprey.h"

/****************************************/
/****************************************/

static const Real TRAP_SIZE         = 0.1f;
static const Real TRAP_MIN_DURATION = 100;
static const Real PREDATOR_RADIUS   = 2.0f;
static const Real MIN_PREY_RADIUS   = 3.0f;
static const Real MAX_PREY_RADIUS   = 4.0f;

/****************************************/
/****************************************/

PredatorPrey::PredatorPrey()
{
	m_unTrappedTimeSteps = 0;
	m_strOutFile = "";
	m_pcRNG = NULL;
}

/****************************************/
/****************************************/

PredatorPrey::~PredatorPrey() {}

/****************************************/
/****************************************/

void PredatorPrey::Init(TConfigurationNode& t_tree)
{
	try
	{
		GetNodeAttributeOrDefault(t_tree, "output", m_strOutFile, {"output.csv"});
	}
	catch (std::exception e)
	{
		LOGERR << "Problem with Attributes" << std::endl;
	}

	// Random number generator
	m_pcRNG = CRandom::CreateRNG("argos");

	// Random position of the robots
	MoveRobots();
}

/****************************************/
/****************************************/

void PredatorPrey::Reset()
{
	// Random position of the robots
	MoveRobots();

	// Reset the variables
	m_vecPreyPosX.clear();
	m_vecPreyPosY.clear();
	m_unTrappedTimeSteps = 0;
	m_vecTrappedTimeSteps.clear();
	m_vecTrapped.clear();
	m_pcRNG = CRandom::CreateRNG("argos");
}

/****************************************/
/****************************************/

void PredatorPrey::Destroy() {}

/****************************************/
/****************************************/

void PredatorPrey::PreStep() {}

/****************************************/
/****************************************/

void PredatorPrey::PostStep()
{
	CSpace::TMapPerType& m_cFootbots = GetSpace().GetEntitiesByType("foot-bot");
	for(CSpace::TMapPerType::iterator it = m_cFootbots.begin(); it != m_cFootbots.end(); ++it)
	{
		// Get handle to foot-bot entity and controller
		CFootBotEntity& cFootBot = *any_cast<CFootBotEntity*>(it->second);

		// Get the position of the *prey* foot-bot in the ground as a CVector2
		if (cFootBot.GetId().find("prey") != std::string::npos)
		{
			m_vecPreyPosX.push_back(cFootBot.GetEmbodiedEntity().GetOriginAnchor().Position.GetX());
			m_vecPreyPosY.push_back(cFootBot.GetEmbodiedEntity().GetOriginAnchor().Position.GetY());
			break;
		}
	}

	// Prey is trapped if it only moves within an area of size (TRAP_SIZE x TRAP_SIZE)
	// for TRAP_MIN_DURATION time steps
	if (m_vecPreyPosX.size() > TRAP_MIN_DURATION)
	{
		Real rMinX = *std::min_element(m_vecPreyPosX.end() - TRAP_MIN_DURATION,
		                               m_vecPreyPosX.end());
		Real rMaxX = *std::max_element(m_vecPreyPosX.end() - TRAP_MIN_DURATION,
		                               m_vecPreyPosX.end());
		Real rMinY = *std::min_element(m_vecPreyPosY.end() - TRAP_MIN_DURATION,
		                               m_vecPreyPosY.end());
		Real rMaxY = *std::max_element(m_vecPreyPosY.end() - TRAP_MIN_DURATION,
		                               m_vecPreyPosY.end());
		Real rDeltaX = std::abs(rMaxX - rMinX);
		Real rDeltaY = std::abs(rMaxY - rMinY);
		if (rDeltaX < TRAP_SIZE && rDeltaY < TRAP_SIZE)
		{
			m_unTrappedTimeSteps += 1;
			m_vecTrapped.push_back(1);
		}
		else
		{
			m_vecTrapped.push_back(0);
		}
		m_vecTrappedTimeSteps.push_back(m_unTrappedTimeSteps);
	}
	else
	{
		m_vecTrapped.push_back(0);
		m_vecTrappedTimeSteps.push_back(0);
	}
	
	// Output in simulator
	if (m_unTrappedTimeSteps == 0)
	{
		LOG << "Prey not trapped" << std::endl;
	}
	else
	{
		LOG << "Prey trapped for a total of " << m_unTrappedTimeSteps << " time steps" << std::endl;
	}
}

/****************************************/
/****************************************/

void PredatorPrey::PostExperiment()
{
	LOG << "End of experiment" << std::endl;
	LOG << "Prey trapped for a total of " << m_unTrappedTimeSteps << " time steps" << std::endl;

	// Log data
	std::ofstream expLogFile;
	expLogFile.open(m_strOutFile);
	if (expLogFile.is_open())
	{
		// Vector of time steps
		UInt32 unTimeSteps = m_vecTrapped.size();
		std::vector<UInt32> vecTimeSteps(unTimeSteps);
		std::iota(std::begin(vecTimeSteps), std::end(vecTimeSteps), 0);

		// Fill log with 4 columns: time step, trapped/not trapped, x, y
		for (UInt32 i = 0; i < unTimeSteps; i++)
		{
			expLogFile << vecTimeSteps.at(i) << ",";
			expLogFile << m_vecTrapped.at(i) << ",";
			expLogFile << m_vecTrappedTimeSteps.at(i) << ",";
			expLogFile << m_vecPreyPosX.at(i) << ",";
			expLogFile << m_vecPreyPosY.at(i) << std::endl;
		}

		// Close log file
		expLogFile.close();
	}
	else
	{
		LOGERR << "Could not open file " << m_strOutFile;
	}
}

/****************************************/
/****************************************/

void PredatorPrey::MoveRobots()
{
	CFootBotEntity* pcFootBot;
	bool bPlaced = false;
	UInt32 unTrials;
	CSpace::TMapPerType& tFootBotMap = GetSpace().GetEntitiesByType("foot-bot");
	for (CSpace::TMapPerType::iterator it = tFootBotMap.begin(); it != tFootBotMap.end(); ++it)
	{
		pcFootBot = any_cast<CFootBotEntity*>(it->second);
		// Choose position at random
		unTrials = 0;
		do
		{
			++unTrials;
			CVector3 cFootBotPosition;
			if (pcFootBot->GetId().find("prey") != std::string::npos)
			{
				cFootBotPosition = GetRandomPreyPosition();
			}
			else
			{
				cFootBotPosition = GetRandomPredatorPosition();
			}
			bPlaced = MoveEntity(pcFootBot->GetEmbodiedEntity(),
			                     cFootBotPosition,
			                     CQuaternion().FromEulerAngles(m_pcRNG->Uniform(CRadians::UNSIGNED_RANGE),
			                     CRadians::ZERO,CRadians::ZERO),false);
		}
		while(!bPlaced && unTrials < 100);
		if(!bPlaced)
		{
			THROW_ARGOSEXCEPTION("Can't place robot");
		}
	}
}

/****************************************/
/****************************************/

CVector3 PredatorPrey::GetRandomPredatorPosition()
{
	Real r = m_pcRNG->Uniform(CRange<Real>(0.0f, PREDATOR_RADIUS));
	CRadians t = m_pcRNG->Uniform(CRange<CRadians>(CRadians::SIGNED_RANGE));
	return CVector3(r, CRadians::PI_OVER_TWO, t);
}

/****************************************/
/****************************************/

CVector3 PredatorPrey::GetRandomPreyPosition()
{
	Real r = m_pcRNG->Uniform(CRange<Real>(MIN_PREY_RADIUS, MAX_PREY_RADIUS));
	CRadians t = m_pcRNG->Uniform(CRange<CRadians>(CRadians::SIGNED_RANGE));
	return CVector3(r, CRadians::PI_OVER_TWO, t);
}

/****************************************/
/****************************************/

// Register this loop functions into the ARGoS plugin system
REGISTER_LOOP_FUNCTIONS(PredatorPrey, "predatorprey");
