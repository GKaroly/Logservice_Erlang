-module(erlangHF).
-export([start/1]).

%start, loop, handle and response methods idea from here:
%https://stackoverflow.com/questions/2206933/how-to-write-a-simple-webserver-in-erlang

%start the server on a port
start(Port) ->
    start_nonstop(),

    %set where to listen and call the loop method
    spawn(fun () -> 
        {ok, Sock} = gen_tcp:listen(Port, [{active, false}]), 
        loop(Sock) end).

%run infinitely
loop(Sock) ->
    %printOut(Sock),
    %get the Conn from gen_tcp:accept
    {ok, Conn} = gen_tcp:accept(Sock),
    %printOut(Conn),
    Handler = spawn(fun () -> 
        handle(Conn) end),
    gen_tcp:controlling_process(Conn, Handler),
    loop(Sock).


printOut(Value)->
    io:fwrite("~p~n",[Value]).
    %io:fwrite("~tp~n", [Value]).

writeToFile(InputString)->
    file:write_file("tempFileForErlangHF.txt", InputString, [append]).

%Handling the HTTP GET request on localhost
handle(Conn) ->
    
    %The beginning of the HTML
    HTMLStringBegin="
      <html>
      <head>
      </head>
      <body>
          <h1>Logs:</h1>
          <table border=\"1\" cellpadding=\"5\">
              <tr>
                  <th>id</th>
                  <th>date</th>
                  <th>from</th>
                  <th>to</th>
                  <th>level</th>
                  <th>message</th>
              </tr>
      ",

    %The end of the HTML
    HTMLStringEnd="
        </table>
        </body>
        </html>
        ",

    %Reads the elements of the table from the file
    Elements=readFromFile(),

    StringForShow=HTMLStringBegin++Elements,
    StringForShow2=StringForShow++HTMLStringEnd,
    Response=response(StringForShow2),

    gen_tcp:send(Conn, Response),
    gen_tcp:close(Conn).

%For writing the Response to the client
response(Str) ->
    %Convert the string into binary
    B = iolist_to_binary(Str),
    iolist_to_binary(
      io_lib:fwrite(
         "HTTP/1.0 200 OK\nContent-Type: text/html\nContent-Length: ~p\n\n~s",
         [size(B), B])).

%Method for get the content from the temp file
readFromFile()->
  {ok, File} = file:read_file("tempFileForErlangHF.txt"), 
  Content = unicode:characters_to_list(File),
  Content.
    
    

%start_nonstop() and nonstop(N) method based from this site:
%https://stackoverflow.com/questions/22712442/how-to-kill-an-infinite-loop-process-in-erlang

%creating a new process
start_nonstop() ->
  spawn(fun() ->
        %delete the previous file if exist
        file:delete("tempFileForErlangHF.txt"),
        Pid = spawn(?MODULE, nonstop(0)),
        exit(Pid, kill)
    end).

%infinitely running method
%for generating new log records
nonstop(N) ->
    
    %creating the datetime and save into a String
    {Y,M,D}=erlang:date(),
    {HH, MM, SS}=erlang:time(),
    DateTimeString=integer_to_list(Y)++" "++
      integer_to_list(M)++"."++
      integer_to_list(D)++". "++
      integer_to_list(HH)++":"++
      integer_to_list(MM)++":"++
      integer_to_list(SS),

    %Concatenation a String about a new line
    NewLine="
      <tr>
          <td>"++integer_to_list(N)++"</td>
          <td>"++DateTimeString++"</td>
          <td>Sender</td>
          <td>Log Server</td>
          <td>0</td>
          <td>Test log message</td>
      </tr>
      ",

    %write the NewLine into a temp file
    writeToFile(NewLine),

    %wait 1 seconds
    timer:sleep(1000),

    %the method calls itself again witch an increased number
    nonstop(N + 1).
