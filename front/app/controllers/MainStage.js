angular.module('bl.analyze.solar.surface')
  .controller('MainStageController', ['$scope',
    function ($scope) {
      $scope.init = function () {
        console.log('Main Stage init');
      };
    }
  ]);