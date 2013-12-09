/**
 * 
 */
package nodeStatistics;

/**
 * @author Stefan Guna
 * 
 */
public class GlobalStatistics {
	static public int acksFailedCount = 0;

	static public int acksReceivedCount = 0;

	static public int beaconsSentCount = 0;

	static public int duplicatesDroppedCount = 0;

	static public int duplicatesReceivedCount = 0;

	static public int lostCount = 0;

	/**
	 * Maximum number of parent overflows.
	 * 
	 * @see nodeStatistics.RuntimeStatistics#parentOverflowCount
	 */
	static public int maxParentOverflow = 0;

	static public int msgCount = 0;

	static public int parentOverflowCount = 0;

	static public int parentChanges = 0;

	static public int txQueueFullCount = 0;

	static public int msgForwarded = 0;
	
	static public int dcIdle = 0;
	
	static public int dcData = 0;
}
