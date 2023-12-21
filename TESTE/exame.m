movies = readcell('films.txt', 'Delimiter', ',');
numMovies = height(movies);

genres = unique(movies(:,3));

fprintf("Genres:\t%20s\t%8s\t%10s\t%10s\n\t\t%20s\t%8s\t%10s\t%10s\n\t%20s\t%8s\t%10s\t%10s\n\t%20s\t%8s\t%10s\t%10s\n\t%20s\t%8s\t%10s\t%10s\n", genres{1:20});