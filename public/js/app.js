var faveTweets = angular.module('faveTweets',['ngResource','ngRoute']);

faveTweets.controller('TweetListController', ['$scope','$routeParams','Tweet','User',
  function($scope,$routeParams,Tweet,User) {
    $scope.user = User.get();
    $scope.updateTweet = function(tweet){
      var entry = Tweet.get({id: tweet.id});
      entry.$update();
    };
}]);

//faveTweets.controller('TagDetailController', ['$scope','$routeParams', 'Tag', function($scope,$routeParams,Tag) {
//  $scope.tag = Tag.get({id: $routeParams.id});
//}]);

faveTweets.factory('Tweet',['$resource',function($resource){
  return $resource('/tweets/:id',{id: '@id'},{
    update: {method: 'PUT'}
  });
}]);

faveTweets.factory('User',['$resource',function($resource){
  return $resource('/users/',{},{
    update: {method: 'PUT'}
  });
}]);

//faveTweets.factory('Tag',['$resource',function($resource){
//  return $resource('/tags/:id',{id: '@id'},{
//    get: {method: 'GET', params:{id:'tags'}, isArray:false}
//  });
//}]);
