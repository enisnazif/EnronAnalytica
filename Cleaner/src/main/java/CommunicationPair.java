public class CommunicationPair implements Comparable<CommunicationPair>
{
  private String To;
  private String From;
  private double Weight;

  public CommunicationPair(String To, String From, double Weight)
  {
    this.To = To;
    this.From = From;
    this.Weight = Weight;
  }

  public String getTo()
  {
    return this.To;
  }

  public String getFrom()
  {
    return this.From;
  }

  public double getWeight()
  {
    return this.Weight;
  }

  public void setWeight(double newWeight)
  {
    this.Weight = newWeight;
  }

  public int compareTo(CommunicationPair other)
  {
    int res = (this.To.compareTo(other.To));

    if (res != 0)
    {
        return res;
    }

    return this.From.compareTo(other.From);
  }

  public boolean isLoop()
  {
    return (this.To.equals(this.From));
  }

  public String toString()
  {
    return (To + ", " + From + ", " + Weight);
  }
}
