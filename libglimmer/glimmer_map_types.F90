!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!                                                             
!   glimmer_map_types.F90 - part of the Community Ice Sheet Model (CISM)  
!                                                              
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!
!   Copyright (C) 2005-2018
!   CISM contributors - see AUTHORS file for list of contributors
!
!   This file is part of CISM.
!
!   CISM is free software: you can redistribute it and/or modify it
!   under the terms of the Lesser GNU General Public License as published
!   by the Free Software Foundation, either version 3 of the License, or
!   (at your option) any later version.
!
!   CISM is distributed in the hope that it will be useful,
!   but WITHOUT ANY WARRANTY; without even the implied warranty of
!   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!   Lesser GNU General Public License for more details.
!
!   You should have received a copy of the Lesser GNU General Public License
!   along with CISM. If not, see <http://www.gnu.org/licenses/>.
!
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifdef HAVE_CONFIG_H
#include "config.inc"
#endif

!> This module contains derived types.
!!
module glimmer_map_types

  use glimmer_global, only: dp
  use glimmer_physcon, only: pi

  implicit none

  !> derived type holding all know map projections. This simulates inheritance
  type glimmap_proj
     logical :: found = .false.
     type(proj_laea),  pointer :: laea  => NULL() !< Pointer to Lambert azimuthal equal area type
     type(proj_aea),   pointer :: aea   => NULL() !< Pointer to Albers equal area conic type
     type(proj_lcc),   pointer :: lcc   => NULL() !< Pointer to Lambert conic conformal type
     type(proj_stere), pointer :: stere => NULL() !< Pointer to Stereographic type
  end type glimmap_proj

  !-------------------------------------------------------------

  !> Lambert Azimuthal Equal Area
  type proj_laea
     real(dp) :: longitude_of_central_meridian  !< longitude of central meridian
     real(dp) :: latitude_of_projection_origin  !< latitude of projection origin
     real(dp) :: false_easting                  !< false easting
     real(dp) :: false_northing                 !< false northing
     real(dp) :: sinp                           !< Sine of latitude_of_projection_origin
     real(dp) :: cosp                           !< Cosine of latitude_of_projection_origin
     integer :: pole                            !< Set to 1 for N pole, -1 for S pole, 0 otherwise
  end type proj_laea

  !-------------------------------------------------------------

  !> Albers Equal-Area Conic
  type proj_aea
     real(dp),dimension(2) :: standard_parallel !< two standard parallels
     real(dp) :: longitude_of_central_meridian  !< longitude of central meridian
     real(dp) :: latitude_of_projection_origin  !< latitude of projection origin
     real(dp) :: false_easting                  !< false easting
     real(dp) :: false_northing                 !< false northing
     real(dp) :: rho0                           !< Convenience constant
     real(dp) :: rho0_R                         !< Convenience constant (is rho0/EQ_RAD)
     real(dp) :: c                              !< Convenience constant
     real(dp) :: n                              !< Convenience constant
     real(dp) :: i_n                            !< Convenience constant (inverse of n)
  end type proj_aea

  !-------------------------------------------------------------

  !> Lambert Conic Conformal
  type proj_lcc
     real(dp),dimension(2) :: standard_parallel !< two standard parallels
     real(dp) :: longitude_of_central_meridian  !< longitude of central meridian
     real(dp) :: latitude_of_projection_origin  !< latitude of projection origin
     real(dp) :: false_easting                  !< false easting
     real(dp) :: false_northing                 !< false northing
     real(dp) :: rho0                           !< Convenience constant
     real(dp) :: f                              !< Convenience constant
     real(dp) :: n                              !< Convenience constant
     real(dp) :: i_n                            !< Convenience constant (inverse of n)
  end type proj_lcc

  !-------------------------------------------------------------

  !> Stereographic projection derived type 
  type proj_stere
     real(dp) :: longitude_of_central_meridian      !< longitude of central meridian        
     real(dp) :: latitude_of_projection_origin      !< latitude of projection origin         
     real(dp) :: scale_factor_at_proj_origin = 0.d0 !< scale factor at origin 
     real(dp) :: standard_parallel = 0.d0           !< a standard parallel
     real(dp) :: false_easting                      !< false easting
     real(dp) :: false_northing                     !< false northing
     integer :: pole                                !< Set to 1 for N pole, -1 for S pole, 0 otherwise
     logical :: equatorial                          !< Set true if equatorial aspect
     real(dp) :: k0                                 !< scale factor or std par converted to scale factor
     real(dp) :: ik0                                !< inverse of k0
     real(dp) :: sinp                               !< sin of latitude_of_projection_origin
     real(dp) :: cosp                               !< cos of latitude_of_projection_origin
     !WHL - Added local area factor for stereographic projections.
     ! TODO: Add area factor for other projections?
     logical :: compute_area_factor = .false.
     real(dp), dimension(:,:), pointer :: area_factor => null()   !< scale factor for area of each grid cell
  end type proj_stere

  ! Global mapping parameters ----------------------------------

!  real(dp),parameter :: pi         = 3.141592654    !< The value of $\pi$.  ! defined in glimmer_physcon
  real(dp),parameter :: M_PI_4     = pi/4.d0        !< The value of $\pi/4$.
  real(dp),parameter :: M_PI_2     = pi/2.d0        !< The value of $\pi/2$.
  real(dp),parameter :: D2R        = pi/180.d0      !< Degrees-to-radians conversion factor.
  real(dp),parameter :: R2D        = 180.d0/pi      !< Radians-to-degrees conversion factor.
  real(dp),parameter :: EQ_RAD     = 6.37d6         !< Radius of the earth (m)
  real(dp),parameter :: i_EQ_RAD   = 1.d0/EQ_RAD  !< Inverse radius of the earth (m^-1)
  real(dp),parameter :: CONV_LIMIT = 1.0d-8         !< Convergence limit (a small number).

  integer, parameter :: GMAP_LAEA=1  !< ID for Lambert azimuthal equal area projection
  integer, parameter :: GMAP_AEA=2   !< ID for Lambert azimuthal equal area projection
  integer, parameter :: GMAP_LCC=3   !< ID for Lambert conformal conic projection
  integer, parameter :: GMAP_STERE=4 !< ID for stereographic projection

contains

  !> return true if structure contains a known projection
  function glimmap_allocated(proj)

    implicit none
    type(glimmap_proj) :: proj
    logical glimmap_allocated

    glimmap_allocated = proj%found
  end function glimmap_allocated

  !> This is incomplete diagnostics code to output full
  !! content of projection type. Only does
  !! Stereographic projections so far.
  subroutine glimmap_diag(proj)

    use glimmer_log

    type(glimmap_proj) :: proj

    if (associated(proj%stere)) then
       call glimmap_diag_stere(proj%stere)
    else
       call write_log('Stereographic projection not found')
    end if

  end subroutine glimmap_diag

  !> print out parameters of Stereographic projection
  subroutine glimmap_diag_stere(params)

    use glimmer_log
    use glimmer_global, only : msg_length

    type(proj_stere) :: params
    character(len=msg_length) :: message
    
    call write_log('***** Stereographic *****')
    write(message,*)'longitude_of_central_meridian:', params%longitude_of_central_meridian
    call write_log(message)
    write(message,*)'latitude_of_projection_origin:', params%latitude_of_projection_origin
    call write_log(message)
    write(message,*)'scale_factor_at_proj_origin:', params%scale_factor_at_proj_origin
    call write_log(message)
    write(message,*)'standard_parallel:', params%standard_parallel
    call write_log(message)
    write(message,*)'false_easting:', params%false_easting
    call write_log(message)
    write(message,*)'false_northing:', params%false_northing
    call write_log(message)
    write(message,*)'pole:', params%pole
    call write_log(message)
    write(message,*)'equatorial:', params%equatorial
    call write_log(message)
    write(message,*)'k0:', params%k0
    call write_log(message)
    write(message,*)'ik0:', params%ik0
    call write_log(message)
    write(message,*)'sinp:', params%sinp
    call write_log(message)
    write(message,*)'cosp:', params%cosp
    call write_log(message)

  end subroutine glimmap_diag_stere

end module glimmer_map_types
