import React, { useEffect, useState } from 'react';
import { hotelBooking, setupContract, web3 } from '../utils/web3';
import { Link } from 'react-router-dom';

const RoomList = () => {
    const [rooms, setRooms] = useState([]); // 방 목록 상태
    const [isLoading, setIsLoading] = useState(true); // 로딩 상태

    useEffect(() => {
        // 방 정보를 가져오는 비동기 함수
        const fetchRooms = async () => {
            try {
                await setupContract(); // 스마트 계약 설정 함수 호출
                const rooms = await hotelBooking.methods.getRooms().call(); // 스마트 계약에서 방 목록 가져오기
                console.log("Rooms fetched from contract:", rooms); // 콘솔에 방 목록 출력
                setRooms(rooms); // 방 목록 상태에 설정
                setIsLoading(false); // 로딩 상태를 false로 설정
            } catch (error) {
                console.error("Error fetching rooms:", error); // 오류 발생 시 콘솔에 출력
                setIsLoading(false); // 로딩 상태를 false로 설정
            }
        };
        fetchRooms(); // 컴포넌트가 마운트될 때 방 정보 가져오기 함수 호출
    }, []);

    if (isLoading) { // 로딩 중인 경우
        return <div>Loading...</div>; // 로딩 메시지 표시
    }

    return (
        <div>
            <h2>Available Rooms</h2> // 방 목록 제목
            <ul>
                {rooms.length > 0 ? ( // 방 목록이 있는 경우
                    rooms.map(room => ( // 각 방을 목록으로 표시
                        <li key={room.id}>
                            {room.name} - {web3.utils.fromWei(room.price.toString(), 'ether')} ETH - 
                            {room.isBooked ? 'Booked' : <Link to={`/book/${room.id}`}>Book Now</Link>}
                            {/* 방 이름, 가격 (ETH로 변환), 예약 상태 표시 */}
                        </li>
                    ))
                ) : (
                    <li>No rooms available</li> // 방 목록이 없는 경우 메시지 표시
                )}
            </ul>
        </div>
    );
};

export default RoomList;
