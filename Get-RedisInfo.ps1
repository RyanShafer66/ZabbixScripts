# Variables
$redisPath = "c:\Redis"
$computer=$env:COMPUTERNAME

# Set the current location to the redis directory
Set-Location -Path $redisPath

# Create an object to store our values
$object = New-Object -TypeName PSObject

# Let's use a switch parser to get the lines we want out of our info
switch -Regex (CMD.EXE /C "C:\Redis\redis-cli.exe -p 6380 INFO") {

    # Get the uptime_in_seconds
    '^uptime_in_seconds:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name uptime_in_seconds -Value $matches[1]
    }
        
    # Get the connected_clients client
    '^connected_clients:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name connected_clients -Value $matches[1]
    }

    #TODO: keyspace

    # Get instantaneous_ops_per_sec
    '^instantaneous_ops_per_sec:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name instantaneous_ops_per_sec -Value $matches[1]
    }

    # Get keyspace_hits
    '^keyspace_hits:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name keyspace_hits -Value $matches[1]
    }
    
    # Get keyspace_misses
    '^keyspace_misses:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name keyspace_misses -Value $matches[1]
    }   

    # Get the rdb_last_save_time (minutes since last save to disk
    '^rdb_last_save_time:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name rdb_last_save_time -Value  ("{0:0.}" -f (New-TimeSpan -Start ((Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($matches[1]))) -End (Get-Date)).TotalMinutes)
    }
    
    # Get the rdb_changes_since_last_save
    '^rdb_changes_since_last_save:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name rdb_changes_since_last_save -Value $matches[1]
    }  
    
    # Get the connected_slaves
    '^connected_slaves:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name connected_slaves -Value $matches[1]
    }    

    # Get the master_last_io_seconds_ago
    '^master_last_io_seconds_ago:(\d+)$' {
    
        $object | Add-Member -MemberType NoteProperty -Name master_last_io_seconds_ago -Value $matches[1]
    }
    
    # Get the used_memory
    '^used_memory:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name used_memory -Value $matches[1]
    }

    # Get the maxmemory
    '^maxmemory:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name max_memory -Value $matches[1]
    }

    # Get the mem_fragmentation_ratio
    '^mem_fragmentation_ratio:(.+)$' {

        $object | Add-Member -MemberType NoteProperty -Name mem_fragmentation_ratio -Value $matches[1]
    }

    # Get the evicted_keys
    '^evicted_keys:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name evicted_keys -Value $matches[1]
    }

    # Get the blocked_clients
    '^blocked_clients:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name blocked_clients -Value $matches[1]
    }

    # Get the rejected_connections
    '^rejected_connections:(\d+)$' {

        $object | Add-Member -MemberType NoteProperty -Name rejected_connections -Value $matches[1]
    }

}

# Calculate the used_memory_percentage
$object | Add-Member -MemberType NoteProperty -Name used_memory_percentage -Value ("{0:0.00}" -f ($object.used_memory/$object.max_memory))

# Calculate the hit_rate
if (([int]$object.keyspace_hits + [int]$object.keyspace_misses) -ne 0) {

    $object | Add-Member -MemberType NoteProperty -Name hit_rate -Value ("{0:0.00}" -f ($object.keyspace_hits/($object.keyspace_hits + $object.keyspace_misses)))
}

# Populate the file with our info
Foreach ($property in ($object | Get-Member -MemberType NoteProperty))
{
   $prop = $property.Name
   $val = $object.$($property.Name)
   CMD.EXE /C "C:\DevOps\zabbix\zabbix_sender.exe -z zabbix.tcetra.local -p 10051 -s $computer -k $prop -o $val" | Out-Null
}
