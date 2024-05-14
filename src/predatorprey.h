#include <argos3/core/simulator/loop_functions.h>
#include <argos3/plugins/robots/foot-bot/simulator/footbot_entity.h>
#include <fstream>
#include <numeric>

using namespace argos;

class PredatorPrey : public CLoopFunctions {

public:

	// Class constructor
	PredatorPrey();

	// Class destructor
	virtual ~PredatorPrey();

	// Initializes the experiment.
	// It is executed once at the beginning of the experiment, i.e., when ARGoS is launched.
	// @param t_tree The parsed XML tree corresponding to the <loop_functions> section.
	virtual void Init(TConfigurationNode& t_tree);

	// Return random positions.
	CVector3 GetRandomPredatorPosition();
	CVector3 GetRandomPreyPosition();

	// Resets the experiment to the state it was right after Init() was called.
	// It is executed every time you press the 'reset' button in the GUI.
	virtual void Reset();

	// Undoes whatever Init() did.
	// It is executed once when ARGoS has finished the experiment.
	virtual void Destroy();

	// Performs actions right before a simulation step is executed.
	virtual void PreStep();

	// Performs actions right after a simulation step is executed.
	virtual void PostStep();

	// Performs actions right after an experiment is finalised.
	virtual void PostExperiment();

private:
	// Method used to reallocate the robots.
	// The position is given by the method GetRandomPosition().
	void MoveRobots();

private:
	// These vectors contain the position of the prey at every time step.
	std::vector<Real> m_vecPreyPosX;
	std::vector<Real> m_vecPreyPosY;

	// Number of time steps when the prey was trapped.
	UInt32 m_unTrappedTimeSteps;
	std::vector<UInt32> m_vecTrappedTimeSteps;

	// Vector of time steps when the prey was trapped (1) or not (0).
	std::vector<bool> m_vecTrapped;

	// The path of the output file.
	std::string m_strOutFile;

	// Random number generator
	CRandom::CRNG* m_pcRNG;
};
