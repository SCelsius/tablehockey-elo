






                          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                          %%%%                                                       %%%%\
                          %%    THE ULTIMATE GUIDE TO THE TABLEHOCKEY RATING SYSTEM    %%\|
                          %                                                             %\|
                          %%                   Author: Simon Sörman                    %%\|
                          %%%%                                                       %%%%\|
                          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\|
                           \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \|
                            ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                         (hockey)Table of Contents                          .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|



               \      _____________________________________________________________________________________
                \____/                               /               . . . . . . . . . . . . . . . . . .   \____
              __/     . . . . . . . . . . . . . . . % . . . .       .                                     .     \__ ________________
       ______/     . .                                                                                       .     \
            /                               SECTION       /                      LINE                         .     \
            |    . . . . . . . . . . . . . . . . . . . . & .                                                   &    |____________________
        ___/                                                 .             . . . . . . . . . . . . . . . %__    \    \
           |         _   .                  (hockey)Table of Contents            26                     .  _     .   |
           |        / |  .                  Preface                              62                     . | \    .   |
           |   \   (  |  |                  Setup                                84                     . |  )   .   |
    _______|    %   > |  &    . . . % . . . Quick Start                     . .  101  . . . & . . . .   . | <    .   |_______
           |    .  (  |  .         /        Most common Statistics & Plots       148       /            % |  )   .   |
           |    .   \_|  .                  Advanced Data Juggling               194                    .\|_/        |
           |    .                           Plots                   .            519                                 |__________
 __________\    .                    |      Statistics                . . . . .  645  . . . __% . . . . . . . . .   /
            |    .     . . . . . . . & . .  End Note                             786                                |
            \     .                         Legal Disclaimer                     835                        . .     /__
        _____\__     .                                     .     . . . . . . . . . . . . . & . . . . . . . .     __/
                \____   . . . . . . . . . . . . . . . . . .                                 \*              ____/
                     \_____________________________________________________________________________________/    \
                                                                                                                 \
                                                                                                                  \



 



 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                                  Preface                                   .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|


Congratulations to your free purchase of this MATRIX System! (MAtlab Tablehockey Rating & statistIX)

This brand new software in your (computer's) hands is the state-of-the-art amateur program
for statistics and visualization of data collected in tablehockey games! (Other games not supported.)

Also included in this product is example data from over 500 games, with over 2000 points scored!
This data was collected by a bunch of crazy tablehockey experts at LinLab over the course of several months.
Most of these games were not played outside of breaks...
In all sincerity, they made for some really good friends! 







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                                   Setup                                    .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|


1. Put the provided folder of files on your computer.
2. Install MATLAB, version 2014b (probably) or later.
3. In Matlab, navigate to the folder mentioned in 1.
4. You're all set to screw things up!







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                                Quick Start                                 .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|

          
>>>>>>>> How to Register a Game <<<<<<<<


    To register a played game, simply use the following command in Matlab:

    >> statlog(gameType, player_names, score, time)

    Where the input arguments should be as follows:
        - gameType:     A string denoting the game type (case-sensitive). 
                        Allowed values are 'single', 'double', 'master' and 'double master'.
        - player_names: A cell-matrix with the player's names as strings (case-sensitive). 
                        Each row of the cell-matrix is considered a team.
                        OBSERVE: in master games, the last player/team is assumed to have
                        started as not playing, which will affect the rating.
        - score:        A vector with the teams' scores.
        - time:         An optional string in a datetime format, or just time.
                        If only time is entered, the current date will be used.
                        If the time argument is not entered, the current date and time will be used.


    When you press enter, the system will be calculated as fast as physically possible and subsequently
    display the change that the entered arguments would incur, together with a prompt to accept the change.
    Enter the letter y to accept, and anything else to decline, e.g. if you entered something wrong.

    Note that if no change is displayed for a player that did play, then that player is not yet rated and needs to play more.
    Furthermore, new players will be added automatically if they have not occured before.

    Games can be entered in any order, everything will be ordered chronologically and recalculated if neccessary.


    Examples:
    >> statlog('single', {'Simon S';'Joel'},                     [6 0],   '2017-01-01 23:59')
    >> statlog('master', {'Joel';'Henrik';'Simon S'},            [0 0 3], '23:59')
    >> statlog('double', {'Simon S','Pradeepa';'Henrik','Joel'}, [5 1])







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                       Most common Statistics & Plots                       .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|


----- How to Plot the Entire Total Rating History:

    >> statplot('hist')


----- How to Plot the current Month's Rating Changes against Days:

    >> statplot('month', 'xaxis', 'days')


----- How to See the Aggregate Score of all Single Games Between Two Players:

    >> statprint('mara', 'single', {'Simon S'; 'Joel'})


----- How to See the total Game Statistics of a Pair of Players in Double Games:

    >> statprint('table', 'double', {'Simon S', 'Pradeepa'})


    Please note the difference in the player-names-cell-matrix in the two most recent examples.
    In the first we want 'Simon S' against 'Joel' => Two different rows.
    In the second we want 'Simon S' in the same team as 'Pradeepa' => Same row.


----- How to See the Longest Win/Lose-Streaks (Amongst others) for all Players:

    >> statprint('streak')


----- How to List the 30 Most Recent Games:

    >> statprint('list', 'latest', 30)







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                           Advanced Data Juggling                           .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|


There are some more advanced stuff that can be done with the data log, 
but that are more complicated to do to make sure you're not doing anything on accident.
These are the functionalities that will be covered in this section:

    - Removing a logged game
    - Removing a player
    - Renaming a player
    - Adding/removing rating systems
    - Set parameters in rating systems
    - Import data
    - Recalculate the entire system


None of these actions are as convenient as statlog(...).
The file statlog.m is intended to enable easy logging of games, 
but if anything else is to be done, the following procedure has to be made:

    1. Load the system:                              >> load('stats.mat')
    2. Perform actions on the variable stat_system:  >> stat_system.action(arguments)
    3. Save the system:                              >> save('stats.mat', 'stat_system')

Of course you could save the updated system to some other file else than stats.mat.
However, all the helping scripts statlog.m, statplot.m and statprint.m assumes that
the file containing the system is named stats.mat, and that the variable is called stat_system.


Throughout the remaainder of this section it is assumed that you have already loaded stat_system,
and that if you would like to keep the changes made, you will save it afterwards.




>>>>>>>> Removing a logged game <<<<<<<<

    If you wish to removed a previously entered game, all you need to do is to figure out that games number.
    This can be found by listing games with statplot('list'), 
    or by searching through the GameLog manually (see last part of this section).
    Tip: the last game has number stat_system.game_log.getNumberOfGames()

    Once the number is found, simply call

    >> stat_system.removeGame(game_nr)


    This will remove the given game, and recalculate everything as if that game never existed.




>>>>>>>> Removing a player <<<<<<<<

    If a player announces it's retirement, it is possible to remove it from the system:

    >> stat_system.removePlayer(player_name)

    The command will prompt you to confirm the action.
    This will NOT remove any data in the system AT ALL. All statistics and all rating history remains.
    What is changed however, is that this player is now considered inactive, and it's rating history will stop updating.
    This means that there will not be a continued horizontal line in the history plots forever and ever and ever and ever...
    This also means that if that player starts playing again sometime in the future, it will start from scratch, i.e. the
    player will have no rating and will suffer through yet another pre-rating period. 
    Note that it is possible to remove a player many times, as long as there is any game inbetween the removals.
    At each removal, the player has to start all over again.

    
    If there already is an annoying horizontal line in the history plot, a player can also be removed historically:

    >> stat_system.removePlayerAtGameNr(player_name, game_nr)

    Which will act as if the removal of the player was performed just after the given game number.
    A great way to determine when to remove a player that has been inactive for a while, and probably will never play again is:

    >> statprint('list', 'vs', player_name, 'latest', 1)

    which will display the player's last game. The number of that game is the most exact choice for removing the player.


    Should you in any way (very probable) do something wrong, want to redo, or take back your removal of a player,
    perhaps it unexpectedly started playing again, the rescue is:

    >> stat_system.reinstatePlayer(player_name)

    which will revert the latest removal of that player, which can continue on it's previous rating.




>>>>>>>> Renaming a player <<<<<<<<

    If a player has to change name, it is easy to do with:

    >> stat_system.renamePlayer(current_name, new_name)

    The command will prompt to ensure that you want to do this action, and if so, change the player name throughout the entire system.




>>>>>>> Rating Systems <<<<<<<<

    A StatSystem() is by default equipped with seven rating systems, all of type BasicEloRatingSystem:
        
       __________________________________________________________________________________________ 
      | Name              Included game types         Start game types        Nr. of start games |
      |¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨|
      | total             all                         single, master          12                 |
      | individual        single, master              single, master          12                 |
      | team              double, double master       double, double master   10                 |
      | single            single                      single                  12                 |
      | master            master                      master                  8                  |
      | double            double                      double                  12                 |
      | double master     double master               double master           12                 |
      |__________________________________________________________________________________________|

                    
                                       _________________________________________________________________________
                                      |                                                                         |                   
                                      |                   INFO: The BasicEloRatingSystem                        |
                                      |                                                                         |
                                      |   This rating system keeps a rating value R for each player.            |
                                      |   When player A with rating R_A and player B with rating R_B face       |
                                      |   each other, the probability of A scoring the next goal is assumed:    |
                                      |                                                                         |
                                      |                                                 1                       |
                                      |       P_AB = P(A scores vs. B) =  -----------------------------   (1)   |
                                      |                                    1 + 0.0025 * 10^(R_B - R_A)          |
                                      |                                                                         |
                                      |                                                                         |
                                      |   The scoring probabilities are then used to calculate each player's    |
                                      |   expected point ratios in the game setup, E_A etc., such that the sum  |
                                      |   of the participating players expected points ratios is 1.             |
                                      |   In a game with total number of points P, and A scoring P_A points,    |
                                      |   A's rating is updated as follows:                                     |
                                      |                                                                         |
                                      |                   R_A_new = R_A + K * (P_A - P * E_A)           (2)     |
                                      |                                                                         |
                                      |   This is based on the classical ELO-model used in for instance chess.  |
                                      |   The parameter K is by default set to 15.                              |
                                      |                                                                         |
                                      |   When a new player starts playing, it has no rating, and thus no       |
                                      |   changes can be calculated. However, when a player has played a set    |
                                      |   amount of games of a set game type, the player's start rating value   |
                                      |   is calculated as the rating that would best predict all the player's  |
                                      |   pre-rating game results according to equation (1). This start value   |
                                      |   is then used and updated as in (2).                                   |
                                      |                                                                         |
                                      |                                                                         |
                                      |      ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨      |
                                      |                                                                         |
                                      |                          Calculation of E_A                             |
                                      |                                                                         |
                                      |   In a single game A vs. B, the calculation of E_A is simple:           |
                                      |                                                                         |
                                      |                             E_A = P_AB                                  |
                                      |                                                                         |
                                      |   The calculation for a master game  A vs. B. vs. C is however more     |
                                      |   convoluted. A Markov chain model is used, with transition             |
                                      |   probabilities troughout being P_AB, P_AC, P_BA, P_BC, P_CA and P_CB.  |
                                      |   Here we're only showing states and transitions where the score is     |
                                      |   still 0,0,0. An m after the score denotes the master, and o denotes   |
                                      |   that the player is outside of playing, i.e. waiting for its turn:     |
                                      |                                                                         |
                                      |                              P_CA                                       |
                                      |            ----> [0m,0o,0] -------> [0o,0,0m]                           |
                                      |           |           ^                  |                              |
                                      |      P_AB |           |                  | P_BC                         |
                                      |           |           |    P_AB          v                              |
                                      |                        ------------ [0,0m,0o]                           |
                                      |    [0,0,0o]                                                             |
                                      |                                                                         |
                                      |           |                                                             |
                                      |      P_BA |                  P_CB                                       |
                                      |            ----> [0o,0m,0] -------> [0,0o,0m]                           |
                                      |                       ^                  |                              |
                                      |                       |                  | P_AC                         |
                                      |                       |    P_BA          v                              |
                                      |                        ------------ [0m,0,0o]                           |
                                      |                                                                         |
                                      |                                                                         |
                                      |   Given that the sum of points is three, each state with sum of points  |
                                      |   being equal to three has a probability (all sum to 1), then:          |
                                      |                                                                         |
                                      |                                                                         |
                                      |                                 ___                                     |
                                      |                    E_A = 1/3 *  \    P_A * P(state)       (3)           |
                                      |                                 /__                                     |
                                      |                                  S                                      |
                                      |                                                                         |
                                      |   Where S is all states with sum of points being three.                 |
                                      |                                                                         |
                                      |      ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨      |
                                      |                                                                         |
                                      |   For games with teams of more than one person, the average R of the    |
                                      |   team is used, and then E of each team is calculated as above.         |
                                      |   The value of K is also divided by the number of players per team.     |
                                      |                                                                         |
                                      |_________________________________________________________________________|


    Note that this structure is valid for rating systems of type BasicEloRatingSystem,
    other rating systems might have completely different types of parameters.


    To add a new rating system, call:

    >> stat_system.addRatingSystem(rating_system_class_name, rating_system_constructor_arguments)

    For instance, to create a new BasicEloRatingSystem called 'no masters' that considers single and double games, 
    but only calculates start ratings on single games:

    >> stat_system.addRatingSystem('BasicEloRatingSystem', 'no masters', {'single','double'}, {'single'}, 8)



    Rating systems can also be removed, using only their name. For example to remove the system 'double':

    >> stat_system.removeRatingSystem('double')

    This will prompt to ensure that you want to remove it, simply enter the letter y to confirm.



    To set a parameter of a rating system to a new value, call:

    >> stat_system.setSystemParameter(system_name, parameter_name, parameter_value)

    For instance to set K in the 'total' system to 30:

    >> stat_system.setSystemParameter('total', 'K', 30)

    This will recalculate the entire system to account for the new parameter value.




>>>>>>>> Import data <<<<<<<<

    Should you create a new StatSystem, but want to import the data from another StatSystem(), simply use:

    >> new_stat_system.importStatSystemData(stat_system)




>>>>>>>> Recalculate the entire system <<<<<<<<

    If for some reason you think you've encountered one of those pesky little bugs that always sneaks around where there is code,
    and therefore your system might have calculated something wrong when you were doing some action, 
    it is possible to make a single recalculation of everything:

    >> stat_system.replayAllGameData()

    This will probably take some time...




>>>>>>>> The GameLog <<<<<<<<

    The GameLog stores all data from all logged games, and provides possiblity to access this data.
    The GameLog can be accessed with stat_system.game_log.
    The data is stored in an array, where elements are structs with the following properties:

    ___________________________________________________________
   |  PROPERTY         DESCRIPTION                             |
   |¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨|
   |  type             A string containing the game type.      |
   |                                                           |
   |  player_names     A cell-matrix containing the player     |
   |                   names, as entered when logging a game.  |
   |                                                           |
   |  time             A datetime-struct with the date and     |
   |                   time the game was played.               |
   |                                                           |
   |  score            A vector with the score of the game.    |
   |                                                           |
   |  win              A matrix of the same size as            |
   |                   player_names. A 1 signals that the      |
   |                   player in that position won, a 0 that   |
   |                   the player didn't win.                  |
   |                                                           |
   |  tie              A matrix of the same size as            |
   |                   player_names. A 1 signals that the      |
   |                   player in that position tied the win,   |
   |                   a 0 that the player didn't.             |
   |                                                           |
   |  player_ids       An IdStruct containing the ids of       |
   |                   the players. The only thing you need to |
   |                   know about this is that it corresponds  |
   |                   to player_names, you can do indexing,   |
   |                   comparison and intersection as with     |
   |                   normal Matlab matrices.                 |
   |___________________________________________________________|


   The GameLog contains many functions to extract certain data, but it is also possible to extract any data with:

   >> game_log.getGameValues(func_handle, game_numbers)
   >> game_log.getGameData(func_handle, game_numbers)

   The first version is for uniform values, and is returned in an array. 
   The second is for any data, and is returned in a cell-array.

   ----- Get the total number of points in all games:

   >> nr_games = game_log.getNumberOfGames();
   >> sum( game_log.getGameValues(@(g) sum(g.score), 1:nr_games) )


   ----- Get the number of games that has been tied:

   >> sum( game_log.getGameValues(@(g) max(g.tie), 1:nr_games) )







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                                   Plots                                    .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|


The file statplot.m is provided to plot a variety of interesting and uninteresting stuff.
The function is called as such:

>> statplot(type, arguments...)

Where type is the name of the type of plot that is wanted (not case-sensitive). 
The available types are:

    __________________________________________________________________________________________________
   |  TYPE         DESCRIPTION                                             Required arguments         |
   |¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨|
   |  bar          Displays a bar graph of the current rating values.                                 |
   |                                                                                                  |
   |  hist         Provides a line graph showing the history of each                                  |
   |               player's rating values.                                                            |
   |                                                                                                  |
   |  all          A bar graph of the distribution of game results.                                   |
   |                                                                                                  |
   |  dist         A bar graph of the distribution of game results         gameType, player_names     |
   |               of a specific setup.                                                               |
   |                                                                                                  |
   |  week         Provides a line graph showing each player's                                        |
   |               change in rating in the week of the latest game.                                   |
   |                                                                                                  |
   |  month        Provides a line graph showing each player's                                        |
   |               change in rating in the month of the latest game.                                  |
   |                                                                                                  |
   |  year         Provides a line graph showing each player's                                        |
   |               change in rating in the year of the latest game.                                   |
   |__________________________________________________________________________________________________|


After the type, it is possible to give zero or more key-value arguments that will modify the plots.
The exception is if the plot has required arguments. Then those arguments should be given as the 
first arguments, WITHOUT keys, in the order given in the table above.

The available arguments are:

    __________________________________________________________________________________________________
   |  KEY           VALUE                                 DESCRIPTION                                 |
   |¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨|
   |  players       Cell containing strings of player     Only plots the specified players, if left   |
   |                names. Or just a single string        out it will plot all players.               |
   |                with a player name. Case-sensitive.                                               |
   |                                                                                                  |
   |  fig           A positive integer.                   Creates the plot in the specified figure    |
   |                                                      number.                                     |
   |                                                                                                  |
   |  xaxis         A string being equal to one of        Sets the x-axis unit for line plots:        |
   |                the valid values.                     - 'game':    1:number_of_considered_games   |
   |                Not case-sensitive.                   - 'game_nr': The game numbers               |
   |                                                      - 'time':    The time the games were played |
   |                                                      - 'day':     Rating at the end of each day  |
   |                                                      - 'week':    Same as 'day', but with weeks  |
   |                                                      - 'month':   Same as 'day', but with months |
   |                                                                                                  |
   |  ratingSystem  A string with a name of a rating      Gets the data from the specified rating     |
   |                system.                               system. Default is system 'total'.          |
   |                                                                                                  |
   |  since         A datetime string.                    Only takes data from games played after     |
   |                                                      the given datetime string.                  |
   |                                                                                                  |
   |  until         A datetime string.                    Only takes data from games played before    |
   |                                                      the given datetime string.                  |
   |                                                                                                  |
   |  gameType      Cell contatining strings of game      Only takes data from games of the given     |
   |                types. Or just a single string        type(s).                                    |
   |                with a game type. Case-sensitive.                                                 |
   |                                                                                                  |
   |  vs            Cell containing strings of player     Only takes data played by the given         |
   |                names. Or just a single string        players. Is by default all players.         |
   |                with a player name. Case-sensitive.                                               |
   |                                                                                                  |
   |  vsand         A boolean value.                      Configures how to filter on argument 'vs'.  |
   |                                                      Default is false, in which case it takes    |
   |                                                      data where at least one of the given        |
   |                                                      players played (OR). If true, takes data    |
   |                                                      where all given players played (AND).       |
   |                                                                                                  |
   |  filter        A function handle, taking a game      Only takes data from games where the        |
   |                struct as input (see previous         specified function returns a truthy value.  |
   |                section, last subsection), and                                                    |
   |                gives boolean output.                                                             |
   |                                                                                                  |
   |  latest        A positive integer.                   When all other filtering is done, only      |
   |                                                      keeps data from at most this many games.    |
   |__________________________________________________________________________________________________|


   It is easy to realize that not all these arguments are applicable to all plots.
   Which are valid when is specified in the Matlab help text:

   >> help statplot

   Also, you will get an error if specifying an illegal argument.


   Some convoluted examples:

   >> statplot('hist', 'fig', 34, 'players', {'Simon S','Henrik'}, 'ratingSystem', 'single', 'until', '17-05-30', 'latest', 34, 'xaxis', 'time')

   >> statplot('dist', 'single', {'Simon S'; 'Joel'}, 'filter', @(g) sum(g.score) == 3)

   >> statplot('all', 'gameType', 'master', 'vs', {'Henrik','Joel'}, 'vsand', true, 'latest', 45)


   If you want to use this plot-tool for a StatSystem in you workspace,
   but do not want to overwrite stats.mat, it is possible to give another
   key-value argument. The key should be 'system' (case-sensitive), and
   the value the StatSystem. This key-value pair HAS to occur before any
   other arguments, even the required ones! Example:

   >> statplot('week', 'system', my_stat_system, 'xaxis', 'day')







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                                 Statistics                                 .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|


The file statprint.m is provided to print a variety of interesting and uninteresting stuff.
The function is called as such:

>> statprint(type, arguments...)

Where type is the name of the type of statistics that is wanted (not case-sensitive). 
The available types are:

    __________________________________________________________________________________________________
   |  TYPE         DESCRIPTION OF STATISTICS                               Required arguments         |
   |¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨|
   |  wins         The number of wins, total win ratio, first and                                     |
   |               latest victory.                                                                    |
   |                                                                                                  |
   |  score        Total number of points, total point ratio and                                      |
   |               instability of the point ratio.                                                    |
   |                                                                                                  |
   |  rating       Total and average rating change, max/min rating                                    |
   |               and max/min change in one game.                                                    |
   |                                                                                                  |
   |  streak       Longest streaks of winning, losing, tying, scoring                                 |
   |               at least 1, and not score at all.                                                  |
   |                                                                                                  |
   |  current      Prints all streaks that players are currently on.                                  |
   |                                                                                                  |
   |  list         Prints a list of descriptions of the games.                                        |
   |                                                                                                  |
   |  mara         Prints the aggregated score of a specific setup.        gameType, player_names     |
   |                                                                                                  |
   |  table        Total and average number of points, instability         gameType, player_names     |
   |               of the point ratio, total number of wins, win                                      |
   |               ratio, and number of ties, in a specified game type,                               |
   |               and for specified individuals/teams.                                               |
   |                                                                                                  |
   |  exp          Print the expected score of a specific game setup.      gameType, player_names     |
   |                                                                                                  |
   |  week         Print best/worst week rating change, and number of                                 |
   |               won weeks, i.e. how many weeks the player was the                                  |
   |               one that gained most rating points.                                                |
   |                                                                                                  |
   |  month        Print best/worst month rating change, and number of                                |
   |               won months, i.e. how many months the player was the                                |
   |               one that gained most rating points.                                                |
   |                                                                                                  |
   |  year         Print best/worst year rating change, and number of                                 |
   |               won years, i.e. how many years the player was the                                  |
   |               one that gained most rating points.                                                |
   |__________________________________________________________________________________________________|


After the type, it is possible to give zero or more key-value arguments that will modify the prints.
The exception is if the statistics has required arguments. Then those arguments should be given as the 
first arguments, WITHOUT keys, in the order given in the table above.

The available arguments are:

    __________________________________________________________________________________________________
   |  KEY           VALUE                                 DESCRIPTION                                 |
   |¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨|
   |  players       Cell containing strings of player     Only prints the specified players, if left  |
   |                names. Or just a single string        out it will print all players.              |
   |                with a player name. Case-sensitive.                                               |
   |                                                                                                  |
   |  ratingSystem  A string with a name of a rating      Gets the data from the specified rating     |
   |                system.                               system. Default is system 'total'.          |
   |                                                                                                  |
   |  since         A datetime string.                    Only takes data from games played after     |
   |                                                      the given datetime string.                  |
   |                                                                                                  |
   |  until         A datetime string.                    Only takes data from games played before    |
   |                                                      the given datetime string.                  |
   |                                                                                                  |
   |  gameType      Cell contatining strings of game      Only takes data from games of the given     |
   |                types. Or just a single string        type(s).                                    |
   |                with a game type. Case-sensitive.                                                 |
   |                                                                                                  |
   |  vs            Cell containing strings of player     Only takes data played by the given         |
   |                names. Or just a single string        players. Is by default all players.         |
   |                with a player name. Case-sensitive.                                               |
   |                                                                                                  |
   |  vsand         A boolean value.                      Configures how to filter on argument 'vs'.  |
   |                                                      Default is false, in which case it takes    |
   |                                                      data where at least one of the given        |
   |                                                      players played (OR). If true, takes data    |
   |                                                      where all given players played (AND).       |
   |                                                                                                  |
   |  filter        A function handle, taking a game      Only takes data from games where the        |
   |                struct as input (see previous         specified function returns a truthy value.  |
   |                section, last subsection), and                                                    |
   |                gives boolean output.                                                             |
   |                                                                                                  |
   |  latest        A positive integer.                   When all other filtering is done, only      |
   |                                                      keeps data from at most this many games.    |
   |__________________________________________________________________________________________________|


   It is easy to realize that not all these arguments are applicable to all statistics.
   Which are valid when is specified in the Matlab help text:

   >> help statprint

   Also, you will get an error if specifying an illegal argument.


   Some convoluted examples:

   >> statprint('win', 'gameType', 'single', 'vs', {'Pradeepa', 'Joel'}, 'vsand', false, 'since', '17-05-12')

   >> statprint('mara', 'single', {'Simon S'; 'Joel'}, 'latest', 25)

   >> statprint('month', 'ratingSystem', 'individual')

   >> statprint('exp', 'single', {'Joel'; 'Henrik'})

   >> statprint('table', 'double', {'Simon S', 'Pradeepa'; 'Henrik', 'Pradeepa'}, 'filter', @(g) any(g.win))


   The last example gives statistics of double games for the pairs Simon S with Pradeepa and Henrik with Pradeepa,
   in games that were not tied (i.e. someone won).


   If you want to use this print-tool for a StatSystem in you workspace,
   but do not want to overwrite stats.mat, it is possible to give another
   key-value argument. The key should be 'system' (case-sensitive), and
   the value the StatSystem. This key-value pair HAS to occur before any
   other arguments, even the required ones! Example:

   >> statprint('week', 'system', my_stat_system, 'players', {'Simon S', 'Joel', 'Henrik'})







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                                  End Note                                  .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|




        ____________________________________________________________________
       /                                                                 /  \
      /                                                                 /__  \
     /                                                                 / /_\  \
    (                                                                 (  \\/  /
     \          Dear Reader,                                           \ _\__/
      \                                                                 \
       |        I'd like to thank you for reading my guide!              |
       |        Now likely this software has nothing to hide,            |
       |        save the occasional bug,                                 |
       \        makes you require a hug,                                 \
        |       but hopefully nothing that'll damage my pride.            |
        |                                                                 |
        |       I want you to know that if something you've missed,       |
        |       I'd be happy and glad to be of assist.                    |
        \       Just send me a mail,                                      \
         |      with E or a snail.                                         |
         |      I vow solemnly you'll never be dissed.                     |
         |                                                                 |
         \      I want to express my sincerest warm thanks,                \
          |     to Joel, Pradeepa, Sakib and to Henks,                      |
          |     Hampus, Maxime.                                             |
         /      You're all a great team,                                   /
         |      you helped me soar to the top of the ranks!                |
         |                                                                 |
        /       With this small peculiar prosaic end note,                /
        |       I'm a captain about to abandon his boat.                  |
        |       We had a good run,                                        |
       /        it was all so much fun.                                  /
      /         Regretful it is, how soon this I wrote.                 /         
     /                                                                 /___
    |                                                                 /  /_\
     \                                                                \__\//
      \________________________________________________________________\__/







 ____________________________________________________________________________________________________________________
|*    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    ¨    *|
|           .-´-.-`-.                                Legal Disclaimer                            .-´-.-`-.           |
|.__________________________________________________________________________________________________________________.|


Please note that by using the provided software herein described,
you are legally required to try to enjoy it.
Failure in doing so will almost be impossible to prosecute,
but it will forever be on your conscience!

You are legally not prohibited from changing the provided source code in any way you see fit.
Although, any distribution of software containing anything from the provided material is required
to mention the original source in said distribution, including the original author. 

Copyright 2017-Inf, Simon Sörman