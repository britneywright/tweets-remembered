var faveTweets = angular.module('faveTweets',['ngResource','ngRoute']);

faveTweets.controller('TweetListController', ['$scope','$routeParams','Tweet','User',
  function($scope,$routeParams,Tweet,User) {
    $scope.user = User.get();
    $scope.updateTweet = function(tweet){
      var entry = Tweet.get({id: tweet.id});
      entry.$update(tweet);
    };
    $scope.stages = [
    {label: 'Active Tweets', value: false},
    {label: 'Archived Tweets', value: true}
  ];
}]);

faveTweets.factory('Tweet',['$resource',function($resource){
  return $resource('/tweets/:id',{},{
    update: {method: 'PUT'}
  });
}]);

faveTweets.factory('User',['$resource',function($resource){
  return $resource('/users/',{},{
    update: {method: 'PUT'}
  });
}]);
