unit Core.Broker.Types;

interface

type
  TBrokerConfig = record
    Id: Integer;
    Name: string;
    Platform: string;
    Host: string;
    Port: Integer;
    Enabled: Boolean;
    LastSymbol: string;
    LastTimeFrame: string;
  end;

  TBrokerConfigArray = array of TBrokerConfig;

implementation

end.
